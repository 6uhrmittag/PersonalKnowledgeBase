# NVIDIA VCR User Guide

## Workflow

1. Start application and SteamVR on an OpenVR system with an HMD and controllers.
2. Run `1_capture.cmd` to record the session:
    - Verify devices and input components.
    - Interact naturally to capture actions.
    - Press `<SPACE>` to create segments (`tracking_<i>.bin` files).
    - Press `<ESC>` to stop recording.
3. (Optional) Apply filters to tracking data (see filter sample readme).
4. (Optional) Copy the `tape` directory to the replay system.
5. (Optional) Update hardware/tracking files for newer VCR versions.
6. Run `2_install_replay.cmd` to install the replay driver:
    - No HMD must be attached.
    - SteamVR must be installed.
7. Start SteamVR; replay driver will emulate HMD and controllers.
8. Replay sessions:
    - `3_replay.cmd` replays full session or `tracking_0.bin`.
    - `3_replay.cmd <i>` replays a specific segment.
    - `3_replay.cmd <i_0> ... <i_n>` replays multiple segments consecutively.
9. (Optional) Run `4_uninstall_replay.cmd` to remove replay driver.

---

## Parameters

**Capture Parameters:**

- `-s <f>`: Sampling frequency (default: 2x HMD frequency).
- `-a <hand>,<name>,<input>`: Define segmentation action (controller).
- `-w <hand>,<name>,<input>`: Define recording start action (controller).
- `-n`: Suppress HMD notifications.
- `-t <ms>`: Notification display time (ms).

**Replay Parameters:**

- `<i_0> .. <i_n>`: Replays specified tracking segments consecutively.

**Replay Configuration (`tape/replay_config.json`):**

- `replaySpeed`: Time scaling (e.g., `0.5` = half speed).
- `updateFrequency_in_Hz`: Input update frequency.
- `interpolate`: Enable/disable interpolation.
- `generateVSync`: Enable/disable VSync signals.
- `vSyncStyle`: 0 = Sleep, 1 = Sleep&Busy, 2 = Busy.
- `playIdleAnimation`: Animate HMD/controllers when idle.

**Hardware Configuration (`tape/hardware.json`):**

- Defines HMD/controller properties (`ETrackedDeviceProperty` values).
- Includes resolution, display frequency, and default poses.

**Convert Tool:**

- `-m [H/T]`: Upgrade hardware/tracking file.
- `-i <name>`: Input filename.
- `-o <name>`: Output filename.

**Helper Tool:**

- `-i`: Show OpenVR/SteamVR install directory.
- `-c`: Show current scene rendering process PID/path.

**Drivers Tool:**

- `show`: List installed SteamVR drivers.
- `cleanup`: Uninstall all VCR drivers.

---

## Supported Hardware

VCR supports tracking any SteamVR devices:

- Oculus Rift, Quest, Quest 2 controllers
- VIVE, VIVE Pro controllers

Unsupported controllers still allow pose capture, but not button inputs.

---

## Automation

Replay driver creates `ready.flag` and `busy.flag` files for synchronization.

Basic automation script flow:

```cmd
Wait for ready.flag
Replay segment
Wait for busy.flag
Wait for ready.flag
Loop
```

Alternative method: monitor disappearance of `run.bin` file to trigger next segment immediately after replay.

Replay configuration can be updated live between segments (e.g., change speed).

---

## Notes

- To loop replays, reset app state before ending capture.
- For hardware testing, record with lowest-end hardware to avoid missing inputs.
- Always check the `logs` folder for capture/replay issues.

---

## Troubleshooting

- Always review `logs` if problems occur.
- Disable SteamVR Dashboard if it interferes.
- Controller input issues may indicate unsupported controllers (check capture logs).
- Do not move the HMD during app/capture startup to avoid calibration errors.
- If replay driver does not load, check SteamVR "Manage Add-Ons" for driver enablement.
- Avoid multiple VCR versions installed simultaneously.
- Hardware and tracking files must match the same setup.
- For persistent issues, contact `VCR-Outreach@nvidia.com` with:
    - Error description
    - VCR version
    - Log files
    - SteamVR system report
