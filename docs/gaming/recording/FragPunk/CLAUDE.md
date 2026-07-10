# CLAUDE.md — FragPunk Vertical Clip Pipeline (TikTok)

Handoff document for Claude Code. This project builds the tooling and workflow around an
OBS → DaVinci Resolve → TikTok pipeline for vertical (9:16) FragPunk gameplay clips,
including a multi-POV replay-editing technique. All research findings are summarized here;
treat unverified items as hypotheses to test empirically.

---

## 1. Project Goal

Produce standout vertical TikTok clips (1080×1920) from FragPunk PC gameplay:

1. Record pristine full-screen 16:9 masters locally in OBS (no livestream, no facecam).
2. Optionally re-record highlight moments from multiple POVs via FragPunk's in-game
   replay system (my POV + opponent POV + optional third angle).
3. Edit/reframe to vertical in DaVinci Resolve; export and upload to TikTok via desktop.

Claude Code's job: turn the manual parts of this pipeline into repeatable configs and
scripts **without ever touching the game client** (see Hard Rules).

---

## 2. Hard Rules

- **NEVER inject into, script, hook, or programmatically drive the FragPunk client.**
  FragPunk ships NetEase's kernel-level anti-cheat ("Phanuel" / NeacSafe driver). This
  applies in replay mode too — the replay player runs inside the live client. Account
  bans are the failure mode. Automation targets are OBS, ffmpeg, the filesystem, and
  DaVinci Resolve — never the game.
- **No input macros against the game** (AutoHotkey send-input etc.). Passive global
  hotkey *listeners* for logging purposes are a gray zone — implement only behind an
  explicit opt-in and document the residual risk (kernel AC can see keyboard hooks).
- **Windows PowerShell, not WSL**, for shell scripts. Python is fine for cross-tool glue.
- **Copies only** for any file experimentation; never modify anything inside the
  FragPunk install directory or its replay storage.
- **Test empirically.** Several findings below are community-sourced or unverified;
  every tool/setting is a hypothesis until confirmed on this machine.

---

## 3. Hardware / Environment

- CPU: AMD Ryzen 7 7800X3D · RAM: 64 GB DDR5-6000
- GPU: RTX 4090 (MSI SUPRIM LIQUID X) — dual 8th-gen NVENC encoders, AV1 + HEVC capable
- Recording target disk: Samsung 980 Pro NVMe (PCIe 4.0)
- Main display: ASUS ROG Strix XG27UCDMG, 27" 4K 240 Hz OLED, G-Sync/VRR, HDR-capable
- Live play settings: 4K ultra, HDR on, VRR, large FOV
- Software: OBS Studio, DaVinci Resolve **21 Free** (verified 2026-07 — external
  scripting unavailable, run §8.4 via Resolve's console; see §7.1), ffmpeg (install if
  missing)

---

## 4. Recording Settings (researched baseline)

### OBS capture — FragPunk specifics

| Item | Setting / Action | Status |
|---|---|---|
| Capture method | Game Capture (never Display/Window) | confirmed community consensus |
| Black screen fix | Run OBS **as Administrator** (anti-cheat runs elevated) | confirmed, multiple sources |
| Overlay conflicts | Close MSI Afterburner / RTSS before OBS, or enable "Use Microsoft Detours API hooking" in RTSS | documented OBS conflict |
| Game display mode | Borderless or Fullscreen | standard |

### OBS output (local recording master)

| Setting | Value | Rationale |
|---|---|---|
| Canvas + Output res | 3840×2160 (no downscale) | max crop headroom for vertical reframe |
| FPS | 120 | 60 fps delivery + 50% slow-mo headroom; TikTok caps at 60 |
| Encoder | NVENC **HEVC** (AV1 only if Resolve decodes it smoothly) | 4090 handles trivially; HEVC decodes reliably in Resolve |
| Rate control | CQP 16 (15–16 at 120 fps; 18–20 acceptable at 60) | constant quality for local recording; never CBR |
| Preset / Tuning | P5–P6 / High Quality, single pass | negligible cost on 4090 |
| Profile | main; Max B-frames 2 (0 if motion smears) | SDR pipeline |
| Container | **MKV**, remux to MP4 after (File → Remux) | crash-safe |
| Audio | multi-track, 256–320 kbps | separate game/mic later |

### Color: SDR only

- Color Format **NV12**, Color Space **Rec. 709**, Range **Limited**.
- **Windows HDR / Auto HDR OFF for recording sessions.** TikTok mangles HDR
  (washed-out output); FragPunk has no native HDR toggle anyway (unconfirmed but
  strongly indicated). Recording SDR removes the entire tone-mapping problem class.

### VRR caveat

G-Sync + uncapped fps causes frame-pacing judder in fixed-rate OBS captures.
For recording sessions: cap FragPunk's in-game framerate (120 or 240) so the source
rate relates cleanly to the 120 fps capture. If judder persists, test with VRR off.

### FOV

Max FOV in FragPunk is 125; the usual competitive range is 100–110. Lower end
(~100–105) makes center-crops look cleaner (less edge distortion, bigger crosshair
area in the 9:16 frame). Recommendation: slightly reduced FOV on recording days.

---

## 5. Multi-POV Replay Technique (the differentiator)

FragPunk has an in-match replay system that allows switching the camera between
players. Established TikTok format (Valorant/CS "POV swap" edits): cut between my POV
and the opponent's POV of the same moment.

### Manual workflow (per highlight ≈ 3–4 min)

1. During play: note round numbers of clip-worthy moments (see logging ideas §8).
2. Right after the session, open the replay (**replays may expire — retention
   unverified; record same-day**).
3. Scrub to just before the moment; start OBS recording **always at the same round-clock
   timestamp** (e.g. exactly at 1:32) → record ~30 s of my POV → stop.
4. Scrub back, switch camera to opponent → record the identical window.
5. Optional third pass (third-person/free cam if the replay offers one — **verify what
   camera modes exist**).
6. Naming scheme: `r{round}_{moment}_{pov}.mkv` → `r7_ace_mypov.mkv`,
   `r7_ace_enemypov.mkv`.

### Known replay quirks

- Camera auto-switches to another player when the spectated player dies/respawns —
  start enemy-POV passes early and babysit the camera.
- Replays are client-side reconstructions; minor desync vs. the live match is normal.
- No supported replay export/download; the replay file format is undocumented.
  (Read-only RE of local replay files = separate curiosity project, **not** part of this
  pipeline. Copies only, and rendering video from a parsed replay would mean rebuilding
  a demo renderer — out of scope.)
- Replay passes have zero latency pressure: graphics settings can be maxed beyond
  live-play comfort, framerate locked.

### Sync strategy for Resolve

Positional game audio differs per POV → audio-waveform sync is unreliable. Instead:
- Primary: **sync at the source** by starting every pass at the same replay clock time →
  clips pre-aligned → multicam sync by "In point".
- Fallback: align manually on a hard visual anchor (killfeed entry, muzzle flash,
  damage number).
- For 15–30 s clips, stacked tracks (V1/V2/V3) + blade cuts are often faster than the
  multicam feature; both should be tested once.

---

## 6. DaVinci Resolve Workflow

- Timeline: **1080×1920** (4K source = ample punch-in headroom).
- Timeline setting "Mismatched resolution files" → **Scale full frame with crop**.
- Reframing: manual Transform (Zoom/Position) keyframes = most predictable for FPS
  (crosshair is naturally centered). Smart Reframe (Studio-only) tends to over-adjust
  on gameplay footage — test, don't trust.
- Preferences: enable "Automatically tag Rec.709 Scene clips as Rec.709-A" for
  consistent color after export.
- Layout variants: center-crop (default), blurred-background bars (when killfeed/HUD
  must survive), stacked layout (informational clips). Keep critical visuals out of the
  bottom ~20% and right ~10% (TikTok UI safe zones).

### Export (Deliver page)

| Setting | Value |
|---|---|
| Format/Codec | MP4 / H.264 (software encode — NVENC export is Studio-only on Windows; fine for 15–30 s clips) |
| Resolution | 1080×1920 |
| FPS | 60 |
| Bitrate | ~10–20 Mbps (TikTok re-encodes above ~15 anyway) |
| Color | Rec.709 |
| Audio | AAC 48 kHz, 192–320 kbps |
| Flags | Force sizing/debayer to highest quality |

### TikTok platform facts (2026, community-sourced)

9:16, 1080×1920, 60 fps max. Upload via **desktop** (~4 GB cap vs ~288 MB iOS /
~72 MB Android in-app). 15–30 s clips perform best; completion rate is the dominant
ranking signal. Hook inside the first ~2 s, cut immediately after the payoff, burn in
captions (muted viewing).

---

## 7. Open Questions / Hypotheses to Verify First

1. **Resolve edition on this machine** — RESOLVED 2026-07: **DaVinci Resolve 21 Free.**
   External scripting is Studio-only, so §8.4 runs from Resolve's built-in console
   (Workspace → Console → Py3). Two knock-on facts, both web-verified: Free on Windows
   hardware-decodes H.264/HEVC since v19 but **8-bit only** (the NV12 OBS pipeline
   satisfies this — never switch capture to 10-bit), and Free has **no NVENC export**
   on Windows (deliver = software H.264, see §6).
2. **OBS WebSocket** — confirm obs-websocket v5 is enabled (built into OBS ≥28) and
   reachable; this is the backbone for recording automation.
3. **FragPunk replay camera modes** — exact controls, free-cam availability, HUD
   toggles, playback speed controls, and replay retention window.
4. **AV1 decode in the installed Resolve version** — mostly moot as of 2026-07:
   community reports AV1 import works in Free since v18, but HEVC 8-bit is
   hardware-decoded in Free on Windows since v19, so the master stays HEVC. Revisit
   only if HEVC misbehaves in practice.
5. **ffmpeg present?** If not: install via winget.
6. Actual disk throughput headroom at 4K120 CQP16 (watch OBS "Dropped Frames
   (Recording)" during a test).

---

## 8. Build Targets for Claude Code

Work in this directory. Prioritize in order; each is independently useful.

### 8.1 OBS profile & scene collection (config-as-code)
Generate an OBS profile (`basic.ini`, `recordEncoder.json`) and a scene collection JSON
implementing §4 exactly, so the setup is reproducible/version-controlled. Include a
README on where OBS stores profiles and how to import.

### 8.2 `record-helper` (Python + obs-websocket)
Interactive CLI for replay-pass recording:
- Prompts for round / moment label / POV (or cycles POVs automatically).
- Starts/stops OBS recording via WebSocket; renames the resulting file to the
  `r{round}_{moment}_{pov}.mkv` scheme; sorts into `sessions/{date}/` folders.
- This automates OBS only — fully anti-cheat-safe.

### 8.3 `postprocess.ps1` (PowerShell + ffmpeg)
Batch step after a session: remux MKV→MP4 (stream copy), optionally generate
low-res proxies for Resolve, verify file integrity, print a session manifest.

### 8.4 `resolve-setup.py` (only if Studio, see §7.1)
Via DaVinci Resolve scripting API: create project/timeline (1080×1920, 60 fps),
import a session folder, auto-stack matching POV sets (`r7_ace_*`) onto V1/V2/V3
aligned at clip start (valid because of the sync-at-source recording discipline).

### 8.5 Highlight logging (design exploration, opt-in only)
Evaluate options for timestamping clip-worthy moments during live play **without
touching the game**: (a) OBS replay-buffer hotkey as a pure timestamp marker (file
creation time = moment), (b) second-device note-taking, (c) passive global hotkey
logger (document kernel-AC gray-zone risk; ship disabled by default). Recommend one.

**DECIDED 2026-07: (a).** The replay buffer is enabled in the 8.1 OBS profile — one
hotkey mid-match saves a 30 s file whose mtime is the timestamp and whose content shows
the moment, with zero anti-cheat surface (plain OBS hotkey, no hook into the game).
`record_helper.py --moments` lists the markers after a session. (b) stays the no-setup
fallback; (c) was **not built** — gray-zone risk for no added value over (a).

### 8.6 Docs
`WORKFLOW.md`: the end-to-end checklist from "recording day prep" (HDR off, RTSS
closed, OBS as admin, fps cap, FOV) through replay passes, postprocess, Resolve edit,
export, desktop upload. Written for future-me at 1 a.m.

---

## 9. First Session Task Sequence

1. Verify environment (§7: Resolve edition, obs-websocket, ffmpeg, AV1 decode).
2. Build 8.1 (OBS config) → import → record a 2-minute live test → check dropped
   frames, judder, file playback in Resolve.
3. Build 8.3 (postprocess) against the test recording.
4. Build 8.2 (record-helper) → dry-run against a real replay session.
5. Resolve test edit: one center-crop clip + one POV-swap clip (stacked tracks vs
   multicam comparison) → export → private TikTok test upload → inspect on phone.
6. Only then: 8.4/8.5 depending on §7 findings.

## 10. Definition of Done (loose, weekend-project style)

One real FragPunk highlight, recorded from two POVs, cut together vertically in
Resolve, uploaded to TikTok as a private test — using the scripts instead of manual
file wrangling. Everything beyond that is polish.
