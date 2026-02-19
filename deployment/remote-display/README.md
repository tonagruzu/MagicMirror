# Remote Display Migration + Rollback Kit

This folder provides a **reversible migration path** between:

- **Stable-A**: current Raspberry Pi local MagicMirror runtime.
- **Pilot-B**: Windows-hosted MagicMirror (`serveronly`) + Raspberry Pi Chromium kiosk display.

## Files

- `windows/New-MMBaselineSnapshot.ps1`
  - Captures current baseline files + git state into a dated snapshot folder.
- `windows/Restore-MMBaselineSnapshot.ps1`
  - Restores captured baseline files back into your MagicMirror workspace.
- `pi/switch-mm-profile.sh`
  - Switches Raspberry Pi launch profile between `stable-a` and `pilot-b`.
- `pi/install-mm-profile-switch.sh`
  - Installs switcher + systemd service + profile directories on Raspberry Pi.
- `pi/mm-profile.service`
  - systemd unit that always launches the currently active profile.
- `pi/mm-profile.env.sample`
  - Environment template for profile paths and host URLs.
- `pi/profile-examples/stable-a/start.sh`
  - Example startup script for existing Pi-local setup.
- `pi/profile-examples/pilot-b/start.sh`
  - Example startup script for Pi kiosk mode pointing to Windows host.

## Windows: create baseline snapshot

Run from PowerShell:

```powershell
Set-Location D:\REPOS\MMM-Core
powershell -ExecutionPolicy Bypass -File .\deployment\remote-display\windows\New-MMBaselineSnapshot.ps1
```

Optional additional files:

```powershell
powershell -ExecutionPolicy Bypass -File .\deployment\remote-display\windows\New-MMBaselineSnapshot.ps1 `
  -AdditionalFiles @('modules\MMM-Telegram\MMM-Telegram.js','modules\MMM-Telegram\node_helper.js')
```

## Windows: run Pilot-B host mode

```powershell
Set-Location D:\REPOS\MMM-Core
npm run config:check
npm run server
```

Use `npm run server:watch` during active edits.

## Raspberry Pi: install profile switcher + autostart service

Copy `deployment/remote-display/pi` to your Pi (for example to `/tmp/pi-remote-display`), then run:

```bash
cd /tmp/pi-remote-display
sudo chmod +x ./install-mm-profile-switch.sh
sudo ./install-mm-profile-switch.sh
```

Create env file from template and update values:

```bash
sudo cp ./mm-profile.env.sample /etc/default/mm-profile
sudo nano /etc/default/mm-profile
```

At minimum, set:

- `MM_LOCAL_PATH` for your current Pi-local MagicMirror folder.
- `MM_HOST_URL` to your Windows host URL (for example `http://192.168.1.10:8080`).

Enable and start service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable mm-profile.service
sudo systemctl restart mm-profile.service
sudo systemctl status mm-profile.service
```

## Cutover to Pilot-B

```bash
switch-mm-profile.sh switch pilot-b
switch-mm-profile.sh status
sudo systemctl restart mm-profile.service
```

## Fast rollback to Stable-A

```bash
switch-mm-profile.sh rollback
switch-mm-profile.sh status
sudo systemctl restart mm-profile.service
```

## Restore Windows baseline config (if needed)

```powershell
Set-Location D:\REPOS\MMM-Core
powershell -ExecutionPolicy Bypass -File .\deployment\remote-display\windows\Restore-MMBaselineSnapshot.ps1 `
  -SnapshotPath .\deployment\remote-display\windows\snapshots\snapshot-YYYYMMDD-HHMMSS
npm run config:check
```

## Recommended rollback trigger checklist

Rollback immediately if one or more are true:

- Pi cannot display refreshed content after Windows service restart.
- Screen is blank or repeatedly crashes.
- Recovery takes more than 5 minutes.
- Network dependency causes unacceptable downtime.

If a trigger is hit, rollback on Pi first (`switch-mm-profile.sh rollback`) and investigate Pilot-B after display service is restored.
