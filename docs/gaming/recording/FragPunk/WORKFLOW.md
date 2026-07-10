# WORKFLOW — recording day to TikTok upload

The end-to-end checklist ([CLAUDE.md §8.6](CLAUDE.md)). Written for future-me at 1 a.m.:
no reasoning, just steps. Background is in the linked notes.

> First time on this machine? Run `scripts/verify-environment.ps1` and do the
> [OBS import](obs/README.md) before any of this.

## 0 · Recording-day prep (5 min, before launching FragPunk)

- [ ] **Windows HDR + Auto HDR OFF** (Settings → Display). SDR end-to-end, no exceptions.
- [ ] **Close MSI Afterburner / RTSS** (or RTSS: "Use Microsoft Detours API hooking").
- [ ] Start **OBS as Administrator** → profile `FragPunk-4K120`, scene `FragPunk`.
- [ ] **Start the replay buffer** (Controls panel) — it's the highlight logger.
- [ ] FragPunk: **cap in-game fps at 120 or 240** (VRR judder), FOV ~100–105
      (cleaner center-crop), Borderless/Fullscreen.
- [ ] 10-second test recording → file plays? Right disk? Dropped frames = 0?
      (*View → Stats*, watch "Dropped Frames (Recording)").

## 1 · Live session

- [ ] Record continuously (Start Recording, not just buffer) — masters land in
      `Videos\FragPunk\masters`.
- [ ] Something clip-worthy happens → **hit the Save-Replay hotkey (F10)**. That's the
      whole logging system: the saved file's timestamp marks the round, its 30 s of
      content shows what happened.
- [ ] After the last match: stop recording, stop replay buffer.

## 2 · Replay passes — same day (replays may expire!)

- [ ] `uv run scripts/record_helper.py --moments` → map the saved
      timestamps to round numbers (match history open).
- [ ] Open the FragPunk replay. Optional: max out graphics — no latency pressure here.
- [ ] `uv run scripts/record_helper.py` → per highlight:
      my POV pass, enemy POV pass, optional extra angle.
      **Same replay-clock start for every pass** — the tool reminds you.
      Camera babysitting: the replay camera auto-jumps when the spectated player dies —
      start enemy passes early; if it jumps mid-window, scrub back and redo the pass.
- [ ] First replay session? Note in [CLAUDE.md §7.3](CLAUDE.md): camera modes
      (free cam?), HUD toggle, playback speed, replay retention, replay clock vs live clock.

## 3 · Postprocess (1 command)

- [ ] `powershell -ExecutionPolicy Bypass -File scripts/postprocess.ps1`
      → remux MKV→MP4, integrity check, manifest. Add `-Proxies` only if Resolve chokes.

## 4 · Resolve edit

- [ ] Project setup — Resolve **21 Free** here, so external scripting is off:
      *Workspace → Console → Py3*, then
      `exec(open(r"<repo path>\scripts\resolve-setup.py").read())`
      ([details](scripts/resolve-setup.py)). Manual fallback: new project,
      timeline **1080×1920 @ 60**, stack POVs on V1/V2/V3 aligned at clip start.
- [ ] Timeline setting *Mismatched resolution files* → **Scale full frame with crop**.
- [ ] Preferences: *Automatically tag Rec.709 Scene clips as Rec.709-A* → on.
- [ ] Reframe: manual Transform keyframes (crosshair is centered anyway). Don't trust
      Smart Reframe on gameplay.
- [ ] POV swap: blade between V-track visibilities. Keep it 15–30 s, hook in first 2 s,
      cut right after the payoff. Captions burned in, clear of the bottom ~20 % and
      right ~10 % (TikTok UI overlays).
- [ ] Deliver: MP4 / **H.264 · 1080×1920 · 60 fps · ~10–20 Mbps · Rec.709 ·
      AAC 48 kHz 192–320 kbps** · force sizing/debayer highest quality.
      (Free = software H.264 encode — NVENC export is Studio-only on Windows; a 30 s
      vertical clip renders in seconds regardless.)

## 5 · Upload (desktop) & verify

- [ ] Upload via **tiktok.com on desktop** (4 GB cap, scheduling).
- [ ] First runs: **private** → watch on the phone → sharpness / safe zones / loudness OK?
- [ ] Then post. Done.

## 6 · Wrap-up (2 min)

- [ ] Session folder has manifest.json? MKVs verified → delete MKV originals if space is tight.
- [ ] New findings (replay UI, judder, encoder, decode) → note them in [CLAUDE.md §7](CLAUDE.md).
