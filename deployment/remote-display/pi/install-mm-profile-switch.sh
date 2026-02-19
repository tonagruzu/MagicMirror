#!/usr/bin/env bash
set -euo pipefail

TARGET_SWITCHER="/usr/local/bin/switch-mm-profile.sh"
TARGET_SERVICE="/etc/systemd/system/mm-profile.service"
TARGET_ENV="/etc/default/mm-profile"
PROFILE_ROOT_DEFAULT="/opt/mm/profiles"
ACTIVE_ROOT_DEFAULT="/opt/mm/current"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo ./install-mm-profile-switch.sh" >&2
  exit 1
fi

install -m 0755 "${SCRIPT_DIR}/switch-mm-profile.sh" "${TARGET_SWITCHER}"
install -m 0644 "${SCRIPT_DIR}/mm-profile.service" "${TARGET_SERVICE}"

mkdir -p "${PROFILE_ROOT_DEFAULT}/stable-a" "${PROFILE_ROOT_DEFAULT}/pilot-b" "${ACTIVE_ROOT_DEFAULT}"

if [[ ! -f "${TARGET_ENV}" ]]; then
  cat > "${TARGET_ENV}" <<'EOF'
# Active profile launcher env
PROFILE_ROOT=/opt/mm/profiles
ACTIVE_LINK_DIR=/opt/mm/current
MM_HOST_URL=http://192.168.1.10:8080
EOF
fi

if [[ -f "${SCRIPT_DIR}/profile-examples/stable-a/start.sh" ]]; then
  install -m 0755 "${SCRIPT_DIR}/profile-examples/stable-a/start.sh" "${PROFILE_ROOT_DEFAULT}/stable-a/start.sh"
fi

if [[ -f "${SCRIPT_DIR}/profile-examples/pilot-b/start.sh" ]]; then
  install -m 0755 "${SCRIPT_DIR}/profile-examples/pilot-b/start.sh" "${PROFILE_ROOT_DEFAULT}/pilot-b/start.sh"
fi

if [[ ! -f "${ACTIVE_ROOT_DEFAULT}/active-profile.txt" ]]; then
  "${TARGET_SWITCHER}" switch stable-a
fi

systemctl daemon-reload
systemctl enable mm-profile.service

echo "Installation completed."
echo "Next steps:"
echo "  1) Edit ${TARGET_ENV} and set MM_HOST_URL"
echo "  2) Validate active profile: ${TARGET_SWITCHER} status"
echo "  3) Start service: systemctl restart mm-profile.service"
