# User Guide: Recording and Replaying Synth Riders Sessions with NVIDIA VCR

## Scenario Overview

This guide walks you through recording a session of **Synth Riders** played on **SteamVR** with **Vive full-body tracking** and a **Quest 3** (connected via **Virtual Desktop**) and replaying the session for high-quality recording using **LIV** and **OBS**. The user operates on *
*Windows 11** with a powerful gaming PC equipped with an **RTX 4090** GPU.

## Requirements

- Windows 11
- SteamVR installed
- Synth Riders installed on Steam
- Quest 3 with Virtual Desktop streaming
- Vive Trackers properly set up for full-body tracking
- NVIDIA VCR toolkit
- LIV and OBS for recording

## Step-by-Step Instructions

### 1. Initial Setup

- Connect your Quest 3 via **Virtual Desktop** and ensure full tracking is functional.
- Verify that **SteamVR** recognizes the **Quest 3** and **Vive Trackers** properly.
- Download and unpack the **NVIDIA VCR** toolkit.

### 2. Capturing the VR Session

#### Preparing for Reliable Replays

To ensure consistent replay:

1. **Launch Synth Riders**.
2. **Start SteamVR**.
3. **Position yourself properly**:
    - Face the main menu.
    - Make sure your head orientation is neutral (not turned or tilted).
    - Avoid any early interaction or random movement.

4. **Start the capture process**:
    - Run `1_capture.cmd`.
    - Confirm that all devices (HMD, Vive Trackers) are recognized.
    - Capture starts immediately.

#### Important steps in Synth Riders:

1. **Menu Navigation**:
    - Point and click the **middle menu item** to access the song list.
2. **Song Selection**:
    - Use the search bar to type and find your song.
    - Select the song and confirm.
3. **Wait for Song Start**:
    - 10-30 seconds typical wait.
    - Stay relatively still until the song loads.
4. **Complete the Song**:
    - Play through.
5. **End Recording**:
    - When the final scoreboard appears, **press `<ESC>`** to stop recording.

#### Canceling or Interrupting a Run

- If you encounter an error, **press `<ESC>`** anytime during capture to terminate.
- If something went wrong (wrong song, bad start), restart SteamVR and begin again from the start.

### 3. Preparing for Replay

- **Turn off** Quest 3 and Vive Trackers.
- Run `2_install_replay.cmd` to install the VCR replay driver.
- Ensure SteamVR remains installed but no real HMD is active.

### 4. Setting Up LIV and OBS

- Launch LIV.
- Configure camera angles and dynamic camera control (use an **Xbox controller** if desired for movement during replay).
- Set up OBS:
    - Create a scene capturing LIV output.
    - Configure for high-quality output (high bitrate, low compression).

#### Automating OBS with Replay

- Optionally use OBS plugins (e.g., Advanced Scene Switcher) or external scripting to start recording when VCR replay starts.
- Sync LIV camera control to manual (Xbox controller) operation during replay.

### 5. Replaying the Session

1. Start SteamVR.
2. Run `3_replay.cmd` to:
    - Replay full session.
    - Or, specify segments individually if `<SPACE>` was used.
3. OBS should be recording.
4. You can control camera views manually during replay.

### 6. Optional Advanced Tweaks

- **Adjust Replay Speed**: Edit `tape/replay_config.json`:
    - `"replaySpeed": 1.0` for normal, or slower/faster if desired.
- **Smooth Replay**: Enable `"interpolate": true` for more fluid movements.
- **Optimize VSync**: Tweak `vSyncStyle` based on performance.

### 7. After Replay

- Run `4_uninstall_replay.cmd` to restore SteamVR for real HMD usage.
- Optionally reboot SteamVR.

## Notes & Best Practices

- **Stable Start Point**: Always face forward and avoid initial random movements.
- **Synchronization Tip**: If automating OBS, test timing carefully to match start of replay.
- **Reliable Segmentation**: Use `<SPACE>` wisely to segment song parts if needed.

## Troubleshooting

- **Replay driver issues**: Check SteamVR Add-Ons menu.
- **Controller input missing**: Vive Trackers only record poses, not button input.
- **Capture/Replays differ**: Ensure stationary HMD during game launch.
- **Broken replays**: Check VCR logs and hardware file consistency.

---

**Result:** You can now record highly reliable, high-quality Synth Riders gameplay using VCR, Quest 3, Vive Trackers, LIV, and OBS!

---

Would you like me to also prepare a troubleshooting checklist and quick-fix flowchart? 🎉

