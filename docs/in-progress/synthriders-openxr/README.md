# SynthRiders won't launch into VR — an old OpenXR API layer meets a new Unity

> Quest 3 + Virtual Desktop (wireless) + SteamVR. Diagnosed and fixed 2026-08-21.

## Symptom

- Launch SynthRiders from Steam. The SteamVR desktop window opens normally.
- In the headset: only the placeholder overlay **"Weiter mit SynthRiders"**, forever.
- On the monitor: the SynthRiders window opens but is **pitch black**.
- `SynthRiders.exe` starts and stays alive — it loads its config and writes its save files. It just
  never presents a frame. `UnityCrashHandler64.exe` exits 0, so **this is not a crash**.
- Other VR games still work fine.

## What actually caused it

**Nothing was misconfigured. The environment drifted underneath a game that wasn't being played.**

Save-file activity in `SynthRidersUC` shows continuous monthly play from 2019 through **January 2026**,
then **nothing at all from February to July 2026**, then August. During that six-month gap, three things
changed independently:

| Date | What changed | Consequence |
|---|---|---|
| 2025-03-21 | LIV registers its `XR_LIV_stabilizer` OpenXR API layer (DLL built 2024-07-20) | Harmless for over a year |
| 2026-05-02 | Virtual Desktop Streamer 1.34.18 installs, registers its own layer and takes the OpenXR `ActiveRuntime` | VDXR now serves all OpenXR apps |
| **2026-07-23** | **SynthRiders updates to v2.16.x — Unity 6000.3.13f1, OpenXR XR Plugin 1.16** | **The trigger** |

The new Unity 6.3 OpenXR stack is what the 2024-vintage LIV layer cannot cope with. Every OpenXR app
loads implicit API layers whether it asks for them or not, so the stale layer poisons instance creation.

So the game broke on **2026-07-23** — silently, while nobody was playing it.

?> There was no "wrong setting" to find, in LIV or anywhere else. This is the ordinary failure mode of a
VR stack: five overlays, a streamer, a runtime and a game all updating on their own schedules, and one
component left behind.

## Root cause

`xrCreateInstance` fails, so the game never gets an OpenXR instance, never gets a session, finds no XR
devices, and falls back to the flat screen while SteamVR waits for frames that never come — until its
60-second launch timeout fires and leaves the placeholder overlay up.

The culprit is LIV's implicit API layer, registered under
`HKCU\SOFTWARE\Khronos\OpenXR\1\ApiLayers\Implicit`. The A/B, both through the normal Steam launch path,
both on SteamVR's runtime:

| LIV layer | `Available Layers` | Result |
|---|---|---|
| enabled | 2 | `xrCreateInstance: XR_ERROR_LAYER_INVALID`, no session |
| **disabled** | 1 | **`XR_SESSION_STATE_FOCUSED`** — running in the headset |

Virtual Desktop's other layer, `XR_APILAYER_VIRTUALDESKTOP_oculus_compatibility`, is **innocent** — it
stays loaded in the working configuration.

### The second face: VDXR

While Virtual Desktop's VDXR held the `ActiveRuntime`, the same failure showed up wearing a different
mask. From `C:\ProgramData\Virtual Desktop\OpenXR.log`:

````text
VirtualDesktopOpenXR - v1.0.10 (C:\Program Files\Virtual Desktop Streamer\OpenXR)
Application: SynthRiders (SynthRiders.exe); Engine: Unity
Application request API version 1.1.53
xrCreateInstance failed with XR_ERROR_API_VERSION_UNSUPPORTED
````

VDXR v1.0.10 refuses an OpenXR **1.1.53** request outright. SteamVR's runtime is also a 1.0 runtime
(1.0.34) but negotiates instead of refusing — with the LIV layer disabled the game creates its instance
at **1.0.34 first try, with zero failures logged**.

!> Whether that 1.1.53 request comes from Unity's plugin or is inflated by the stale layer sitting in the
chain was **not** established. It stopped mattering once the layer was gone. Worth testing if VDXR's
lower latency is ever wanted: disable the layer, point `ActiveRuntime` back at VDXR, and see whether it
now negotiates down to 1.0.

### Why it was so hard to pin down

- **Unity's error message points at the wrong thing.** Unity logs `XR_ERROR_LAYER_INVALID` in both cases,
  even where the runtime's own log says `XR_ERROR_API_VERSION_UNSUPPORTED`. Trust the **runtime's** log.
- **The VDXR failure masked the layer failure.** While VDXR held the runtime, the layer never got a
  chance to fail, so fixing only the runtime looked like it changed nothing.
- **OpenVR titles are unaffected** — they never touch the OpenXR runtime or its API layers. VRChat worked
  throughout (`StartVRSDK: OpenVRLoader`), which made it feel like "VR works, this one game is broken".
- **A believed-good session that never was** — see the warning below.

## The fix

### Disable LIV's OpenXR stabilizer layer

`1` = disabled, `0` = enabled. This lives in **HKCU**, so no elevation is needed:

````powershell
Set-ItemProperty 'HKCU:\SOFTWARE\Khronos\OpenXR\1\ApiLayers\Implicit' `
  -Name 'C:\Program Files (x86)\Steam\steamapps\common\LIV\Resources\OpenXR\Stabilizer\manifest.json' `
  -Value 1 -Type DWord
````

?> **This does not break LIV capture in SynthRiders.** SynthRiders ships the LIV SDK natively — the
working run still logs `LIV: Created capture protocol: Bridge` and `LIV: instance created successfully`.
`XR_LIV_stabilizer` is LIV's *First Person Stabilizer* injector for games **without** native LIV support.
If that feature is needed elsewhere, flip the value back to `0`.

!> LIV may re-register its layer (value back to `0`) after an update. If SynthRiders breaks again out of
nowhere, check this value first — `Check-VRStack.ps1` prints it.

### Keep SteamVR as the OpenXR runtime

Needed while VDXR is 1.0-only, and wanted anyway: LIV, fpsVR, OVR Toolkit, OpenVR-SpaceCalibrator and
OyasumiVR are all **SteamVR overlays**, and LIV documents that Virtual Desktop's OpenXR runtime must be
set to SteamVR for LIV Mixed Reality, Avatar, First Person Stabilizer and Streamerkit.

Setting the registry key is **not enough** — Virtual Desktop rewrites
`HKLM\SOFTWARE\Khronos\OpenXR\1\ActiveRuntime` back to VDXR within seconds of connecting. Use the
loader-level override, which per the Khronos loader spec bypasses the registry entirely:

````powershell
# elevated
[Environment]::SetEnvironmentVariable('XR_RUNTIME_JSON',
  'C:\Program Files (x86)\Steam\steamapps\common\SteamVR\steamxr_win64.json', 'Machine')

# revert
[Environment]::SetEnvironmentVariable('XR_RUNTIME_JSON', $null, 'Machine')
````

!> Environment variables are inherited **at process creation**, and the game inherits from the Steam
client — so Steam has to be restarted (or the machine rebooted) before this takes effect. A partial
restart makes the change look useless.

### Why the obvious fixes do nothing

| Attempt | Why it can't work |
|---|---|
| Reinstall the game | The fault is outside the game files |
| Steam file integrity verification | Same |
| Switching version branches (`open-beta`, etc.) | Same |
| Launch option `-vrmode openvr` | Legacy Unity VR flag; Unity XR Plugin Management / OpenXR ignores it |
| SteamVR → "set SteamVR as OpenXR runtime" button | Crashed with `Exception c0000005` and never wrote the setting |
| Writing `ActiveRuntime` in the registry | Virtual Desktop overwrites it on connect |
| Setting `ActiveRuntime` from a non-elevated shell | `HKLM` needs elevation — fails quietly enough to look like it worked |

## Diagnosing this class of problem

Nothing here needs the headset on. Run `Check-VRStack.ps1` (sitting next to this note) for a verdict from
all of it at once.

| Log | What it tells you |
|---|---|
| `%USERPROFILE%\AppData\LocalLow\Kluge Interactive\SynthRiders\Player.log` | The decisive one. `Available Layers: (n)` and whether a session reached `FOCUSED`. `Player-prev.log` is the run before |
| `C:\ProgramData\Virtual Desktop\OpenXR.log` | VDXR's own account of the last instance request: app, API version, real error. Overwritten every launch |
| `C:\Program Files (x86)\Steam\logs\xrclient_SynthRiders.txt` | SteamVR's OpenXR client log — see the warning below before trusting it |
| `C:\Program Files (x86)\Steam\logs\vrserver.txt` | `AppTransition: Aborting external launch because of timeout after 60s` — this line *is* the stuck placeholder overlay |

!> **`xrclient_SynthRiders.txt` existing or being fresh does NOT mean the game worked.** It is written as
soon as the game loads SteamVR's OpenXR client library, including on launches that fail immediately. A
previous investigation treated a fresh timestamp as proof of a good session and built its whole timeline
on a 2026-08-08 run that had in fact **never rendered** — costing hours. To tell a real session from a
dead one, look *inside* the file for:
- `Received success response from vrserver connect` / `vrcompositor connect`
- `Transitioning XrSession ... to XR_SESSION_STATE_READY`
- on older SteamVR builds, a burst of `[Settings] Load Default Json Settings from ...\drivers\...` lines —
  driver enumeration only happens on a real connection

A failed launch logs only the `startup with PID=...` banner and a couple of `steamvr.vrsettings` loads.

### Reading a Unity OpenXR log

````text
# broken
[XR] Available Layers: (2)
[XR] xrCreateInstance: XR_ERROR_LAYER_INVALID
[Subsystems] Failed to initialize subsystem OpenXR Display [error: 1]

# working
[XR] Available Layers: (1)
[XR] Runtime Name: SteamVR/OpenXR
[XR] XrInstance Created with OpenXR API Version: 1.0.34
[XR] XR_SESSION_STATE_VISIBLE->XR_SESSION_STATE_FOCUSED
````

`XR_SESSION_STATE_FOCUSED` is the goal — the game is rendering in the headset and has input focus.

?> **Beware double instances when testing.** Launching `SynthRiders.exe` directly makes Steam relaunch it,
so two processes run and `Player.log` rotates under you — which makes results look random. Dropping a
`steam_appid.txt` containing `885000` next to the exe stops the relaunch and gives clean single-instance
tests. Remove it afterwards.

?> **String-scanning a DLL cannot tell you which OpenXR version it supports.** Versions are packed numeric
constants, not ASCII. Use the runtime's behaviour and its own log instead.

## Environment this was diagnosed on

| Item | Value |
|---|---|
| Game | Synth Riders 2.16.7, AppID 885000, buildid 24297306, branch `open-beta` (updated 2026-07-23) |
| Engine | Unity 6000.3.13f1, IL2CPP, OpenXR XR Plugin 1.16 |
| Headset | Meta Quest 3 (SteamVR mislabels it "Oculus Quest2" — Virtual Desktop's shim naming, harmless) |
| Link | Virtual Desktop Streamer 1.34.18 (installed 2026-05-02), wireless, SteamVR mode |
| VDXR | v1.0.10 — refuses OpenXR 1.1.53 |
| SteamVR | buildid 23791826 (updated 2026-06-18), OpenXR 1.0.34 |
| Overlays | LIV 2.16.3, fpsVR, OVR Toolkit, OpenVR-SpaceCalibrator, OyasumiVR |
| LIV layer | `LIV.OpenXR-Stabilizer-Layer.dll` built 2024-07-20, registered 2025-03-21 |
| GPU | RTX 4090, driver 32.0.16.1047, HAGS on |

?> Software known to grab the OpenXR `ActiveRuntime` key: the Oculus PC app, Meta Quest Developer Hub, and
Virtual Desktop — especially right after an update. If an OpenXR game suddenly stops working, check that
key and the implicit layer list first.

## Loose ends

- `xrEndFrame: XR_ERROR_HANDLE_INVALID` appears periodically during play. It does not stop the game — a
  full run played fine — and it coincides with session state changes (headset off/on, dashboard).
- Whether the `XR_RUNTIME_JSON` override is still needed now that the layer is disabled is **untested**.
  Upstream [VDXR](https://github.com/mbucchia/VirtualDesktop-OpenXR) implements OpenXR 1.1, so a later
  Streamer build may remove the need entirely.
