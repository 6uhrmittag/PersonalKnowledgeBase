# FragPunk → TikTok vertical clip pipeline

Record FragPunk gameplay as 4K120 OBS masters, re-record highlights from multiple POVs
via the in-game replay, cut vertical 9:16 clips in DaVinci Resolve, upload to TikTok.
Spec and research: [CLAUDE.md](CLAUDE.md) · recurring checklist: [WORKFLOW.md](WORKFLOW.md).

**Hard rule:** nothing here ever touches the game client — FragPunk ships kernel-level
anti-cheat. Automation targets OBS, ffmpeg, the filesystem and Resolve only.

**Status:** built 2026-07-10, untested on the gaming PC. Resolve there is **21 Free**
(verified): scripting via Resolve's console, software H.264 export, 8-bit HEVC decode
only — everything is configured for that.

## First test — one quick match (≈30 min total)

On the gaming PC, in PowerShell, from this directory:

1. **Environment check:**
   `powershell -ExecutionPolicy Bypass -File scripts\verify-environment.ps1`
   Fix any FAIL (typically: enable the OBS WebSocket server, `winget install Gyan.FFmpeg astral-sh.uv`).
2. **Import the OBS config** (~5 min): follow [obs/README.md](obs/README.md) — copy
   profile + scene collection, set the recording path, bind `F10` to Save Replay.
3. **Prep:** Windows HDR **off**, Afterburner/RTSS closed, OBS **as Administrator**,
   in-game fps capped at 120/240, replay buffer started.
4. **Play one match:** Start Recording. Hit `F10` whenever something is clip-worthy.
5. **Right after:** OBS *View → Stats* — Dropped Frames (Recording) must be 0. Then
   `powershell -ExecutionPolicy Bypass -File scripts\postprocess.ps1` remuxes and
   verifies the master; drag the MP4 into Resolve and scrub it (decode check).
6. **Got a highlight?** Open the match replay and run
   `uv run scripts\record_helper.py` → record one `mypov` + one `enemypov` pass
   (start both at the same replay-clock time). Import both into Resolve — stacked on
   V1/V2 at clip start they should be in sync. That's the whole technique proven.

Anything that fails or surprises → note it in [CLAUDE.md §7](CLAUDE.md).

## Map

| Path | What |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Spec, research, hard rules, open questions (source of truth) |
| [WORKFLOW.md](WORKFLOW.md) | Recording day end-to-end: prep → record → replay passes → edit → upload |
| [obs/](obs/README.md) | OBS profile & scene collection as importable files, with import steps |
| [scripts/verify-environment.ps1](scripts/verify-environment.ps1) | Automated environment checks (CLAUDE.md §7) |
| [scripts/record_helper.py](scripts/record_helper.py) | Interactive replay-pass recorder (OBS via obs-websocket, `uv run`) |
| [scripts/postprocess.ps1](scripts/postprocess.ps1) | Remux MKV→MP4, integrity check, optional proxies, manifest |
| [scripts/resolve-setup.py](scripts/resolve-setup.py) | Builds the stacked multi-POV Resolve project — run from Resolve's console (Free) |
