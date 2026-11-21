#!/usr/bin/env bash

run_with_personal_secrets() {
  local host="$1"
  shift
  local -a command=("$@")

  if [[ "$host" == rhodium ]]; then
    local has_explicit_override=false
    local index=0
    while (( index < ${#command[@]} )); do
      case "${command[index]}" in
        --override-input)
          if [[ "${command[index+1]:-}" == personal-secrets ]]; then
            has_explicit_override=true
          fi
          ;;
        --override-input=personal-secrets)
          has_explicit_override=true
          ;;
      esac
      index=$((index + 1))
    done

    if [[ "$has_explicit_override" == false ]]; then
      local secrets_path="${PERSONAL_SECRETS_PATH:-}"
      if [[ -z "$secrets_path" ]]; then
        if [[ -z "${HOME:-}" ]]; then
          echo 'HOME is unset; set PERSONAL_SECRETS_PATH to the personal secrets checkout.' >&2
          return 1
        fi
        secrets_path="$HOME/workspace/nix/nix-secrets"
      fi
      if [[ "$secrets_path" != /* ]]; then
        secrets_path="$PWD/$secrets_path"
      fi
      if [[ ! -d "$secrets_path" ]]; then
        printf 'Personal secrets checkout not found: %s\nSet PERSONAL_SECRETS_PATH to its location.\n' \
          "$secrets_path" >&2
        return 1
      fi
      command+=(--override-input personal-secrets "path:$secrets_path")
    fi

    # An input override must never rewrite the tracked lock file with a local path.
    command+=(--no-write-lock-file)
  fi

  "${command[@]}"
}
