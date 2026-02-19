#!/usr/bin/env bash
set -euo pipefail

if [[ -f /etc/default/mm-profile ]]; then
  # shellcheck disable=SC1091
  source /etc/default/mm-profile
fi

PROFILE_ROOT="${PROFILE_ROOT:-/opt/mm/profiles}"
ACTIVE_LINK_DIR="${ACTIVE_LINK_DIR:-/opt/mm/current}"
ACTIVE_LINK_PATH="${ACTIVE_LINK_PATH:-${ACTIVE_LINK_DIR}/start.sh}"
STATE_FILE="${STATE_FILE:-${ACTIVE_LINK_DIR}/active-profile.txt}"

usage() {
  cat <<EOF
Usage:
  switch-mm-profile.sh status
  switch-mm-profile.sh switch <stable-a|pilot-b>
  switch-mm-profile.sh rollback
  switch-mm-profile.sh start

Conventions:
  - ${PROFILE_ROOT}/stable-a/start.sh   (current working setup)
  - ${PROFILE_ROOT}/pilot-b/start.sh    (new Windows-hosted display setup)
  - ${ACTIVE_LINK_PATH} points to selected profile start script
EOF
}

require_profile_start_script() {
  local profile="$1"
  local candidate="${PROFILE_ROOT}/${profile}/start.sh"

  if [[ ! -x "${candidate}" ]]; then
    echo "Profile script not found or not executable: ${candidate}" >&2
    exit 1
  fi
}

current_profile() {
  if [[ -f "${STATE_FILE}" ]]; then
    cat "${STATE_FILE}"
  else
    echo "unknown"
  fi
}

set_profile() {
  local profile="$1"
  require_profile_start_script "${profile}"

  mkdir -p "${ACTIVE_LINK_DIR}"
  ln -sfn "${PROFILE_ROOT}/${profile}/start.sh" "${ACTIVE_LINK_PATH}"
  echo "${profile}" > "${STATE_FILE}"

  echo "Active profile set to: ${profile}"
  echo "Linked ${ACTIVE_LINK_PATH} -> ${PROFILE_ROOT}/${profile}/start.sh"
}

start_active_profile() {
  if [[ ! -x "${ACTIVE_LINK_PATH}" ]]; then
    echo "Active profile link missing: ${ACTIVE_LINK_PATH}" >&2
    echo "Run: switch-mm-profile.sh switch stable-a" >&2
    exit 1
  fi

  exec "${ACTIVE_LINK_PATH}"
}

command="${1:-}"

case "${command}" in
  status)
    echo "Active profile: $(current_profile)"
    if [[ -L "${ACTIVE_LINK_PATH}" ]]; then
      echo "Active link: ${ACTIVE_LINK_PATH} -> $(readlink "${ACTIVE_LINK_PATH}")"
    else
      echo "Active link: not configured"
    fi
    ;;

  switch)
    profile="${2:-}"
    if [[ -z "${profile}" ]]; then
      usage
      exit 1
    fi
    case "${profile}" in
      stable-a|pilot-b)
        set_profile "${profile}"
        ;;
      *)
        echo "Unsupported profile: ${profile}" >&2
        usage
        exit 1
        ;;
    esac
    ;;

  rollback)
    set_profile "stable-a"
    ;;

  start)
    start_active_profile
    ;;

  *)
    usage
    exit 1
    ;;
esac
