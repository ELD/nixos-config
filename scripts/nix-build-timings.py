#!/usr/bin/env python3
"""Summarize derivation builds from timestamp-wrapped Nix internal-JSON logs.

Nix 2.35.2 defines ``actBuild`` as activity type 105 (see
src/libutil/include/nix/util/logging.hh). Its derivation-building goal emits
fields as [derivation store path, remote builder name, ...] (see
src/libstore/build/derivation-building-goal.cc). We match start/stop by activity
ID and only time type-105 activities; substitutions, transfers, build output,
and unstructured log gaps are not derivation durations.
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

BUILD_ACTIVITY_TYPE = 105


def parse_timestamp(value: Any) -> dt.datetime | None:
    if not isinstance(value, str):
        return None
    try:
        parsed = dt.datetime.fromisoformat(value[:-1] + "+00:00" if value.endswith("Z") else value)
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return None
    return parsed.astimezone(dt.timezone.utc)


def timestamp_text(value: dt.datetime | None) -> str | None:
    if value is None:
        return None
    return value.isoformat(timespec="milliseconds").replace("+00:00", "Z")


def activity_id(value: Any) -> str | None:
    if isinstance(value, bool) or not isinstance(value, (int, str)):
        return None
    text = str(value)
    return text if text else None


def derivation_name(path: str) -> str:
    return Path(path).name[:-4] if path.endswith(".drv") else Path(path).name


@dataclass
class ActiveBuild:
    activity_id: str
    derivation_path: str
    started_at: dt.datetime | None
    text: str | None
    builder: str | None


class Diagnostics:
    KEYS = (
        "input_lines",
        "malformed_wrappers",
        "invalid_timestamps",
        "non_nix_messages",
        "malformed_nix_messages",
        "ignored_actions",
        "ignored_activity_types",
        "malformed_build_events",
        "duplicate_starts",
        "unmatched_stops",
        "invalid_event_order",
        "completed_builds",
        "incomplete_builds",
        "untimed_builds",
        "input_errors",
    )

    def __init__(self) -> None:
        self.counts = dict.fromkeys(self.KEYS, 0)

    def __getitem__(self, key: str) -> int:
        return self.counts[key]

    def increment(self, key: str) -> None:
        self.counts[key] += 1


@dataclass
class TimingReport:
    completed: list[dict[str, Any]]
    incomplete: list[dict[str, Any]]
    diagnostics: Diagnostics
    capture_start: dt.datetime | None
    capture_end: dt.datetime | None

    def as_json(self, source: str) -> dict[str, Any]:
        span = self.capture_span_seconds
        return {
            "schema_version": 1,
            "source": source,
            "activity_type": BUILD_ACTIVITY_TYPE,
            "activity_type_name": "build",
            "captured_event_wall_clock_span_seconds": span,
            "completed_build_duration_sum_seconds": round(
                sum(item["duration_seconds"] or 0 for item in self.completed), 6
            ),
            "completed_build_count": len(self.completed),
            "incomplete_build_count": len(self.incomplete),
            "parallelism_note": (
                "The sum of per-derivation durations can exceed the captured event wall-clock "
                "span because builds may overlap; the sum is not elapsed job time. The span "
                "is the log timestamp range and includes non-build activity and gaps."
            ),
            "completed_builds": self.completed,
            "incomplete_builds": self.incomplete,
            "diagnostics": self.diagnostics.counts,
        }

    @property
    def capture_span_seconds(self) -> float | None:
        if self.capture_start is None or self.capture_end is None:
            return None
        return round((self.capture_end - self.capture_start).total_seconds(), 6)


def _build_record(
    build: ActiveBuild,
    stopped_at: dt.datetime | None,
    *,
    incomplete: bool,
    last_capture: dt.datetime | None,
    reason: str | None = None,
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "activity_id": build.activity_id,
        "derivation_path": build.derivation_path,
        "derivation_name": derivation_name(build.derivation_path),
        "activity_text": build.text,
        "builder": build.builder or "local",
        "started_at": timestamp_text(build.started_at),
    }
    if incomplete:
        elapsed = None
        if build.started_at is not None and last_capture is not None:
            elapsed = round(max(0.0, (last_capture - build.started_at).total_seconds()), 6)
        result.update(
            {
                "status": "incomplete",
                "stopped_at": None,
                "elapsed_seconds_at_last_capture": elapsed,
                "last_capture_at": timestamp_text(last_capture),
                "incomplete_reason": reason or "stop_event_not_captured",
            }
        )
        # Deliberately no duration_seconds: an unfinished activity is not a duration.
    else:
        result.update(
            {
                "status": "completed",
                "stopped_at": timestamp_text(stopped_at),
                "duration_seconds": (
                    round((stopped_at - build.started_at).total_seconds(), 6)
                    if build.started_at is not None and stopped_at is not None
                    else None
                ),
            }
        )
    return result


def parse_events(lines: Iterable[str], source: str = "nix-check.events.jsonl") -> TimingReport:
    diagnostics = Diagnostics()
    active: dict[str, ActiveBuild] = {}
    completed: list[dict[str, Any]] = []
    abandoned: list[tuple[ActiveBuild, str]] = []
    capture_start: dt.datetime | None = None
    capture_end: dt.datetime | None = None

    for line in lines:
        diagnostics.increment("input_lines")
        try:
            wrapper = json.loads(line)
        except (json.JSONDecodeError, TypeError):
            diagnostics.increment("malformed_wrappers")
            continue
        if not isinstance(wrapper, dict) or not isinstance(wrapper.get("message"), str):
            diagnostics.increment("malformed_wrappers")
            continue

        timestamp = parse_timestamp(wrapper.get("timestamp"))
        if timestamp is None:
            diagnostics.increment("invalid_timestamps")
        else:
            capture_start = timestamp if capture_start is None else min(capture_start, timestamp)
            capture_end = timestamp if capture_end is None else max(capture_end, timestamp)

        message = wrapper["message"]
        if not message.startswith("@nix "):
            diagnostics.increment("non_nix_messages")
            continue
        try:
            event = json.loads(message[5:])
        except json.JSONDecodeError:
            diagnostics.increment("malformed_nix_messages")
            continue
        if not isinstance(event, dict):
            diagnostics.increment("malformed_nix_messages")
            continue

        action = event.get("action")
        if action not in ("start", "stop"):
            # Activity results, message events, and phase updates are not timers.
            diagnostics.increment("ignored_actions")
            continue

        # Nix's JSONLogger includes type on starts, but stopActivity() emits only
        # {action, id}. Thus the active build-ID set is the authoritative type
        # discriminator for stop events; filtering stops by type would lose all
        # real build durations. (See src/libutil/logging.cc in Nix 2.35.2.)
        event_id = activity_id(event.get("id"))
        if event_id is None:
            if action == "start" and event.get("type") == BUILD_ACTIVITY_TYPE:
                diagnostics.increment("malformed_build_events")
            elif action == "stop" and event.get("type") == BUILD_ACTIVITY_TYPE:
                diagnostics.increment("malformed_build_events")
            continue

        if action == "start":
            if event.get("type") != BUILD_ACTIVITY_TYPE:
                diagnostics.increment("ignored_activity_types")
                continue
            fields = event.get("fields")
            if (
                not isinstance(fields, list)
                or not fields
                or not isinstance(fields[0], str)
                or not fields[0].endswith(".drv")
            ):
                diagnostics.increment("malformed_build_events")
                continue
            if event_id in active:
                diagnostics.increment("duplicate_starts")
                abandoned.append((active.pop(event_id), "duplicate_start_replaced_activity"))
            builder = fields[1] if len(fields) > 1 and isinstance(fields[1], str) else None
            text = event.get("text") if isinstance(event.get("text"), str) else None
            active[event_id] = ActiveBuild(event_id, fields[0], timestamp, text, builder)
            continue

        build = active.pop(event_id, None)
        if build is None:
            # Untyped stops are normal for every Nix activity and can't be
            # classified when their corresponding (non-build) start was ignored.
            if event.get("type") == BUILD_ACTIVITY_TYPE:
                diagnostics.increment("unmatched_stops")
            continue
        if build.started_at is not None and timestamp is not None and timestamp < build.started_at:
            diagnostics.increment("invalid_event_order")
            record = _build_record(build, timestamp, incomplete=False, last_capture=None)
            record["duration_seconds"] = None
            record["timing_error"] = "stop_timestamp_precedes_start_timestamp"
            completed.append(record)
            diagnostics.increment("untimed_builds")
            continue
        record = _build_record(build, timestamp, incomplete=False, last_capture=None)
        if record["duration_seconds"] is None:
            diagnostics.increment("untimed_builds")
        completed.append(record)

    last_capture = capture_end
    incomplete = [
        _build_record(build, None, incomplete=True, last_capture=last_capture, reason=reason)
        for build, reason in abandoned
    ]
    incomplete.extend(
        _build_record(build, None, incomplete=True, last_capture=last_capture)
        for build in active.values()
    )
    diagnostics.counts["completed_builds"] = len(completed)
    diagnostics.counts["incomplete_builds"] = len(incomplete)

    # Put the longest completed derivations first. Keep incomplete entries separate.
    completed.sort(
        key=lambda item: (
            item["duration_seconds"] is not None,
            item["duration_seconds"] or 0,
            item["derivation_path"],
            item["started_at"] or "",
        ),
        reverse=True,
    )
    incomplete.sort(key=lambda item: (item["derivation_path"], item["started_at"] or ""))
    return TimingReport(completed, incomplete, diagnostics, capture_start, capture_end)


def format_duration(seconds: float | None) -> str:
    if seconds is None:
        return "unknown"
    if seconds >= 60:
        minutes, remainder = divmod(seconds, 60)
        return f"{int(minutes)}m {remainder:.1f}s"
    return f"{seconds:.3f}s"


def render_markdown(report: TimingReport, top: int = 10) -> str:
    total = sum(item["duration_seconds"] or 0 for item in report.completed)
    lines = [
        "# Nix derivation build timings",
        "",
        f"- Completed build activities: **{len(report.completed)}**",
        f"- Incomplete build activities: **{len(report.incomplete)}**",
        f"- Sum of completed per-derivation durations: **{format_duration(total)}**",
        "- Overall captured event wall-clock span: **{}**".format(
            format_duration(report.capture_span_seconds)
        ),
        "",
        "> Per-derivation time uses matched Nix `actBuild` (type 105) start/stop events. "
        "The captured event span includes non-build work and gaps; the sum can exceed it "
        "when builds run in parallel. Neither value assigns output lines or silent gaps "
        "to a derivation. A matched stop means the activity ended, not that the build "
        "succeeded; the original Nix check exit status determines success.",
        "",
        f"## Top {max(0, top)} completed builds",
        "",
        "| # | Derivation | Duration | Builder |",
        "|---:|---|---:|---|",
    ]
    if report.completed and top > 0:
        for index, item in enumerate(report.completed[:top], 1):
            name = item["derivation_name"].replace("|", "\\|")
            builder = str(item["builder"]).replace("|", "\\|")
            lines.append(f"| {index} | `{name}` | {format_duration(item['duration_seconds'])} | {builder} |")
    else:
        lines.append("| — | No completed build activities found | — | — |")
    lines.extend(
        [
            "",
            "Incomplete activities report elapsed time at the last captured timestamp, "
            "not a completed duration.",
            "",
            "### Parser diagnostics",
            "",
            "| Counter | Count |",
            "|---|---:|",
        ]
    )
    for name, count in report.diagnostics.counts.items():
        lines.append(f"| `{name}` | {count} |")
    if report.incomplete:
        lines.extend(["", "### Incomplete activities", ""])
        for item in report.incomplete:
            lines.append(
                f"- `{item['derivation_name']}` — elapsed at last capture: "
                f"{format_duration(item['elapsed_seconds_at_last_capture'])} "
                f"({item['incomplete_reason']})"
            )
    return "\n".join(lines) + "\n"


def render_summary(report: TimingReport, top: int = 5) -> str:
    total = sum(item["duration_seconds"] or 0 for item in report.completed)
    lines = [
        "### Nix build timing summary",
        "",
        f"{len(report.completed)} completed; {len(report.incomplete)} incomplete. "
        f"Per-derivation duration sum: **{format_duration(total)}**; captured event span: "
        f"**{format_duration(report.capture_span_seconds)}** (log timestamp range; includes non-build activity/gaps; "
        "parallel builds can make the sum larger). Completed means a stop event was "
        "captured, not that the build succeeded.",
    ]
    if report.completed:
        lines.append("Top builds: " + ", ".join(
            f"`{item['derivation_name']}` {format_duration(item['duration_seconds'])}"
            for item in report.completed[:top]
        ))
    lines.extend(
        [
            "",
            "See `nix-build-timings.md` and `nix-build-timings.json` in the workflow artifact "
            "for the full report.",
            "",
        ]
    )
    return "\n".join(lines)


def run(args: argparse.Namespace) -> int:
    diagnostics: Diagnostics | None = None
    try:
        with open(args.input, encoding="utf-8") as source_file:
            report = parse_events(source_file, source=args.input)
    except OSError as error:
        diagnostics = Diagnostics()
        diagnostics.increment("input_errors")
        report = TimingReport([], [], diagnostics, None, None)
        print(f"Unable to read Nix event log {args.input!r}: {error}", file=sys.stderr)

    output = report.as_json(args.input)
    Path(args.json_output).write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    markdown = render_markdown(report, args.top)
    Path(args.markdown_output).write_text(markdown, encoding="utf-8")
    if args.summary_file:
        with open(args.summary_file, "a", encoding="utf-8") as summary_file:
            summary_file.write(render_summary(report))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", default="nix-check.events.jsonl", help="timestamp-wrapped Nix JSONL input")
    parser.add_argument("--json-output", default="nix-build-timings.json")
    parser.add_argument("--markdown-output", default="nix-build-timings.md")
    parser.add_argument("--summary-file", default=os.environ.get("GITHUB_STEP_SUMMARY"))
    parser.add_argument("--top", type=int, default=10, help="number of longest completed builds in Markdown")
    return run(parser.parse_args(argv))


if __name__ == "__main__":
    raise SystemExit(main())
