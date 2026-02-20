# Readme_ConfigSwitch

Step-by-step guide to run two modes and switch quickly:

- **Stable-A**: Raspberry Pi runs local MagicMirror (current setup).
- **Pilot-B**: Windows PC runs MagicMirror server, Raspberry Pi shows it in Chromium kiosk.

---

## 1) Prerequisites

### Windows PC (Host)
1. MagicMirror repo is available at `D:\REPOS\MMM-Core`.
2. Node and npm are installed and working.
3. Windows PC has a fixed LAN IP (recommended).
4. Firewall allows inbound TCP on your MagicMirror port (default `8080`) from Raspberry Pi.

### Raspberry Pi (Client)
1. Raspberry Pi OS with desktop and Chromium installed.
2. Existing local MagicMirror (your current Stable-A) is working.
3. `sudo` access available.
4. Network access to Windows host IP.

---

## 2) Windows Host Setup (Pilot-B backend)

### Step 2.1 - Validate config and baseline
Run in PowerShell:

```powershell
Set-Location D:\REPOS\MMM-Core
npm run config:check
powershell -ExecutionPolicy Bypass -File .\deployment\remote-display\windows\New-MMBaselineSnapshot.ps1
```

### Step 2.2 - Ensure host bind/port/ipWhitelist are correct
Edit your active config and verify:

- `address` is reachable from Pi (for LAN use, typically `0.0.0.0` or host LAN IP).
- `port` matches what Pi will use (example `8080`).
- `ipWhitelist` includes Pi IP/subnet.

Then re-check:

```powershell
npm run config:check
```

### Step 2.3 - Start host server
For normal runtime:

```powershell
npm run server
```

For active editing sessions (auto reload workflow):

```powershell
npm run server:watch
```

Keep this running on Windows while Pi is in Pilot-B.

---

## 3) Raspberry Pi Setup (Profile switch + autostart)

### Step 3.1 - Copy deployment files to Pi
Copy folder `deployment/remote-display/pi` from this repo to Pi, for example:

- destination on Pi: `/tmp/pi-remote-display`

### Step 3.2 - Install switcher and systemd service
On Pi:

```bash
cd /tmp/pi-remote-display
sudo chmod +x ./install-mm-profile-switch.sh
sudo ./install-mm-profile-switch.sh
```

This installs:

- `/usr/local/bin/switch-mm-profile.sh`
- `/etc/systemd/system/mm-profile.service`
- profile folders under `/opt/mm/profiles`
- active profile link under `/opt/mm/current`

### Step 3.3 - Configure profile environment

```bash
sudo cp ./mm-profile.env.sample /etc/default/mm-profile
sudo nano /etc/default/mm-profile
```

Set at least these values:

- `MM_LOCAL_PATH=/home/pi/MagicMirror` (or your real local MM path)
- `MM_HOST_URL=http://<WINDOWS_IP>:8080` (example `http://192.168.1.10:8080`)

### Step 3.4 - Enable and start autostart service

```bash
sudo systemctl daemon-reload
sudo systemctl enable mm-profile.service
sudo systemctl restart mm-profile.service
sudo systemctl status mm-profile.service
```

---

## 4) First Profile Initialization

Set Stable-A as default first:

```bash
switch-mm-profile.sh switch stable-a
switch-mm-profile.sh status
sudo systemctl restart mm-profile.service
```

Confirm Pi starts your local MagicMirror.

---

## 5) Switch to Pilot-B

### Step 5.1 - Ensure Windows host is running
On Windows:

```powershell
Set-Location D:\REPOS\MMM-Core
npm run server
```

### Step 5.2 - Switch Pi profile
On Pi:

```bash
switch-mm-profile.sh switch pilot-b
switch-mm-profile.sh status
sudo systemctl restart mm-profile.service
```

Pi should now display the Windows-hosted MagicMirror URL.

---

## 6) Rollback to Stable-A (Fast Return)

If Pilot-B does not meet expectations:

```bash
switch-mm-profile.sh rollback
switch-mm-profile.sh status
sudo systemctl restart mm-profile.service
```

This returns Pi to local current setup (Stable-A).

---

## 7) Restore Windows Baseline (if host config changed badly)

1. Find snapshot directory created earlier under:
   `D:\REPOS\MMM-Core\deployment\remote-display\windows\snapshots\snapshot-YYYYMMDD-HHMMSS`
2. Restore with:

```powershell
Set-Location D:\REPOS\MMM-Core
powershell -ExecutionPolicy Bypass -File .\deployment\remote-display\windows\Restore-MMBaselineSnapshot.ps1 `
  -SnapshotPath .\deployment\remote-display\windows\snapshots\snapshot-YYYYMMDD-HHMMSS
npm run config:check
```

---

## 8) Daily Operations

### Work in Stable-A
- Keep Pi on `stable-a`.
- Run local Pi MagicMirror as usual.

### Work in Pilot-B
- Edit only on Windows repo.
- Run Windows host with `npm run server` (or `server:watch` while editing).
- Keep Pi on `pilot-b`.

### Verify active profile any time

```bash
switch-mm-profile.sh status
```

---

## 9) Quick Troubleshooting

1. **Pi blank screen after switch**
   - Check service: `sudo systemctl status mm-profile.service`
   - Immediate recovery: `switch-mm-profile.sh rollback && sudo systemctl restart mm-profile.service`

2. **Pilot-B not reachable**
   - Verify Windows server is running.
   - Verify `MM_HOST_URL` in `/etc/default/mm-profile`.
   - Verify Windows firewall and IP whitelist allow Pi.

3. **Config errors on host**
   - Run `npm run config:check` on Windows before restart.

---

## 10) Recommended Acceptance Criteria before keeping Pilot-B

- Pi survives reboot and returns to selected profile automatically.
- Switching profiles takes less than 5 minutes.
- Pilot-B remains stable for at least 3 consecutive days.
- Rollback drill to Stable-A succeeds in one attempt.
