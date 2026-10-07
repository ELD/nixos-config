import importlib.util
import json
import sys
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "nix-build-timings.py"
SPEC = importlib.util.spec_from_file_location("nix_build_timings", SCRIPT)
assert SPEC and SPEC.loader
TIMINGS = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = TIMINGS
SPEC.loader.exec_module(TIMINGS)


def wrapper(timestamp, event_or_message):
    message = event_or_message if isinstance(event_or_message, str) else "@nix " + json.dumps(event_or_message)
    return json.dumps({"timestamp": timestamp, "message": message})


def start(activity_id, drv, timestamp, *, activity_type=105, fields=None, text=None):
    return wrapper(
        timestamp,
        {
            "action": "start",
            "id": activity_id,
            "type": activity_type,
            "level": 4,
            "text": text or f"building '{drv}'",
            "fields": fields if fields is not None else [drv, "", 1, 1],
        },
    )


def stop(activity_id, timestamp, *, activity_type=None):
    event = {"action": "stop", "id": activity_id}
    if activity_type is not None:
        event["type"] = activity_type
    return wrapper(timestamp, event)


class NixBuildTimingsTests(unittest.TestCase):
    def test_interleaved_builds_pair_by_id_and_sort_by_duration(self):
        events = [
            start(10, "/nix/store/aaa-first.drv", "2025-01-01T00:00:00Z"),
            start(20, "/nix/store/bbb-second.drv", "2025-01-01T00:00:01Z"),
            stop(10, "2025-01-01T00:00:04Z"),
            stop(20, "2025-01-01T00:00:08Z"),
        ]
        report = TIMINGS.parse_events(events)
        self.assertEqual([b["activity_id"] for b in report.completed], ["20", "10"])
        self.assertEqual([b["duration_seconds"] for b in report.completed], [7.0, 4.0])
        self.assertEqual(report.capture_span_seconds, 8.0)
        self.assertEqual(report.diagnostics["completed_builds"], 2)

    def test_cached_copy_and_substitution_events_are_excluded(self):
        events = [
            start(3, "/nix/store/not-a-build.drv", "2025-01-01T00:00:00Z", activity_type=100),
            stop(3, "2025-01-01T00:00:20Z", activity_type=100),
            start(4, "/nix/store/download.drv", "2025-01-01T00:00:02Z", activity_type=108),
            stop(4, "2025-01-01T00:00:30Z", activity_type=108),
        ]
        report = TIMINGS.parse_events(events)
        self.assertEqual(report.completed, [])
        self.assertEqual(report.incomplete, [])
        self.assertEqual(report.diagnostics["ignored_activity_types"], 2)

    def test_incomplete_build_uses_last_capture_as_elapsed_not_duration(self):
        report = TIMINGS.parse_events(
            [
                start(1, "/nix/store/aaa-building.drv", "2025-01-01T00:00:00Z"),
                wrapper("2025-01-01T00:00:05Z", "ordinary output line"),
            ]
        )
        incomplete = report.incomplete[0]
        self.assertEqual(incomplete["elapsed_seconds_at_last_capture"], 5.0)
        self.assertNotIn("duration_seconds", incomplete)
        self.assertEqual(incomplete["status"], "incomplete")
        self.assertEqual(report.diagnostics["non_nix_messages"], 1)

    def test_malformed_rows_and_messages_are_tolerated_and_counted(self):
        report = TIMINGS.parse_events(
            [
                "not json",
                json.dumps({"timestamp": "not-a-time", "message": "@nix {bad"}),
                json.dumps({"timestamp": "2025-01-01T00:00:00Z"}),
                wrapper("2025-01-01T00:00:01Z", "@nix []"),
                wrapper("2025-01-01T00:00:02Z", {"action": "result", "id": 1, "type": 105}),
            ]
        )
        self.assertEqual(report.completed, [])
        self.assertEqual(report.diagnostics["malformed_wrappers"], 2)
        self.assertEqual(report.diagnostics["invalid_timestamps"], 1)
        self.assertEqual(report.diagnostics["malformed_nix_messages"], 2)
        self.assertEqual(report.diagnostics["ignored_actions"], 1)

    def test_utc_offsets_builder_and_drv_fields_are_preserved(self):
        drv = "/nix/store/aaa-thing.drv"
        report = TIMINGS.parse_events(
            [
                start(
                    44,
                    drv,
                    "2025-03-04T01:00:00+01:00",
                    fields=[drv, "remote-builder", 1, 1],
                    text="building a derivation",
                ),
                stop(44, "2025-03-04T00:00:02Z"),
            ]
        )
        build = report.completed[0]
        self.assertEqual(build["derivation_path"], drv)
        self.assertEqual(build["derivation_name"], "aaa-thing")
        self.assertEqual(build["started_at"], "2025-03-04T00:00:00.000Z")
        self.assertEqual(build["duration_seconds"], 2.0)
        self.assertEqual(build["builder"], "remote-builder")

    def test_duplicate_active_id_replaced_and_unmatched_stop_counted(self):
        report = TIMINGS.parse_events(
            [
                start(7, "/nix/store/aaa-old.drv", "2025-01-01T00:00:00Z"),
                start(7, "/nix/store/bbb-new.drv", "2025-01-01T00:00:02Z"),
                stop(7, "2025-01-01T00:00:05Z"),
                stop(999, "2025-01-01T00:00:06Z", activity_type=105),
            ]
        )
        self.assertEqual(report.diagnostics["duplicate_starts"], 1)
        self.assertEqual(report.diagnostics["unmatched_stops"], 1)
        self.assertEqual(report.completed[0]["derivation_name"], "bbb-new")
        self.assertEqual(report.incomplete[0]["derivation_name"], "aaa-old")
        self.assertEqual(report.incomplete[0]["elapsed_seconds_at_last_capture"], 6.0)

    def test_bad_build_fields_and_invalid_timestamps_do_not_make_false_duration(self):
        report = TIMINGS.parse_events(
            [
                start(1, "/nix/store/valid.drv", "2025-01-01T00:00:03Z"),
                stop(1, "2025-01-01T00:00:01Z"),
                wrapper(
                    "2025-01-01T00:00:04Z",
                    {"action": "start", "id": 2, "type": 105, "fields": ["not-a-drv"]},
                ),
            ]
        )
        self.assertEqual(report.diagnostics["invalid_event_order"], 1)
        self.assertIsNone(report.completed[0]["duration_seconds"])
        self.assertEqual(report.as_json("events.jsonl")["completed_build_duration_sum_seconds"], 0)
        self.assertEqual(report.diagnostics["malformed_build_events"], 1)

    def test_untimed_builds_can_be_serialized(self):
        for started, stopped in [
            ("not-a-time", "2025-01-01T00:00:02Z"),
            ("2025-01-01T00:00:03Z", "2025-01-01T00:00:01Z"),
        ]:
            with self.subTest(started=started, stopped=stopped):
                report = TIMINGS.parse_events([
                    start(1, "/nix/store/untimed.drv", started),
                    stop(1, stopped),
                ])
                output = json.loads(json.dumps(report.as_json("test.jsonl")))
                self.assertIsNone(output["completed_builds"][0]["duration_seconds"])
                self.assertEqual(output["completed_build_duration_sum_seconds"], 0)

    def test_markdown_explains_parallel_sum_and_incomplete_semantics(self):
        report = TIMINGS.parse_events(
            [start(1, "/nix/store/a.drv", "2025-01-01T00:00:00Z")]
        )
        markdown = TIMINGS.render_markdown(report)
        self.assertIn("parallel", markdown)
        self.assertIn("not a completed duration", markdown)
        self.assertIn("not that the build succeeded", markdown)
        self.assertNotIn("duration_seconds", markdown)


if __name__ == "__main__":
    unittest.main()
