# OBS config-as-code — FragPunk 4K120 master profile

Implements [CLAUDE.md §4](../CLAUDE.md) as importable files: a profile (`basic.ini` +
`recordEncoder.json`) and a scene collection (`scene-collection.json`).
Everything here is a **researched baseline, unverified on this machine** — after import,
run the 2-minute live test from [WORKFLOW.md](../WORKFLOW.md) before trusting it.

## Where OBS stores these (Windows)

| What | Path |
|---|---|
| Profiles | `%APPDATA%\obs-studio\basic\profiles\<ProfileName>\` |
| Scene collections | `%APPDATA%\obs-studio\basic\scenes\<Name>.json` |

## Import steps

1. **Close OBS** (it rewrites configs on exit and would clobber the copy).
2. Create `%APPDATA%\obs-studio\basic\profiles\FragPunk-4K120\` and copy
   `basic.ini` + `recordEncoder.json` into it.
3. Copy `scene-collection.json` to `%APPDATA%\obs-studio\basic\scenes\FragPunk.json`.
4. Start OBS **as Administrator** (FragPunk's anti-cheat runs elevated; non-admin OBS =
   black screen). Select *Profile → FragPunk-4K120* and *Scene Collection → FragPunk*.
5. Set the recording path (not in the ini — OBS doesn't expand env vars):
   *Settings → Output → Recording → Recording Path* → `%USERPROFILE%\Videos\FragPunk\masters`
   (the 980 Pro). Same tab: confirm replay buffer is on (30 s).
6. Bind the replay-buffer save hotkey: *Settings → Hotkeys → Replay Buffer → Save Replay*
   (suggestion: `F10`). This is the highlight *timestamp marker*: hit it mid-match and
   the saved 30 s file both timestamps and shows the moment (CLAUDE.md §8.5).
7. *Settings → Audio*: point *Game Audio* / *Mic* at the real devices if `default` picked
   the wrong ones. Track routing is preconfigured (game → track 1, mic → track 2).

## What the profile encodes

3840×2160 canvas and output (no downscale) · 120 fps · NVENC **HEVC**, CQP 16, preset p5,
tune hq, single pass, 2 B-frames, main profile · NV12 / Rec.709 / limited range · MKV
container (remux to MP4 in postprocess) · audio tracks 1+2 at 320 kbps · replay buffer 30 s.

## Known caveats (check on first launch)

- **Encoder ID drift:** `RecEncoder=jim_hevc_nvenc` is the pre-OBS-31 ID. If Settings →
  Output shows x264 or "encoder not found" on a newer OBS, the NVENC rewrite renamed the
  IDs — edit `basic.ini` to `RecEncoder=obs_nvenc_hevc_tex` (OBS ≥31) or simply re-pick
  *NVENC HEVC* in the UI and verify the settings against the table above.
- **Scene JSON is minimal:** OBS fills missing fields with defaults on load. Eyeball the
  scene after import: Game Capture present and fullscreen, both audio sources metering,
  cursor capture off.
- **Game capture mode** is `any_fullscreen` — no dependency on the FragPunk window title.
  If it doesn't hook, try *Borderless* in-game, and close MSI Afterburner / RTSS first
  (or enable "Use Microsoft Detours API hooking" in RTSS).
- **Stay 8-bit (NV12):** Resolve Free on Windows decodes H.264/HEVC at **8-bit only** —
  switching OBS to 10-bit (P010) would make the masters unreadable in Resolve 21 Free.
  The NV12/SDR pipeline is a hard requirement, not a preference.
- **B-frames:** if fast motion smears, set `bf` to `0` in `recordEncoder.json` (or in the UI).
- OBS rewrites both files with the full key set on first save — that's normal. To
  re-export a tuned config back into this repo, close OBS and copy the files back here.
