# SynthRiders won't launch into VR — two stacked OpenXR faults

> Quest 3 + Virtual Desktop (wireless) + SteamVR. Diagnosed and fixed 2026-08-21.

## Symptom

- Launch SynthRiders from Steam. The SteamVR desktop window opens normally.
- In the headset: only the placeholder overlay **"Weiter mit SynthRiders"**, forever.
- On the monitor: the SynthRiders window opens but is **pitch black**.
- `SynthRiders.exe` starts and stays alive — it loads its config and writes its save files. It just
  never presents a frame. `UnityCrashHandler64.exe` exits 0, so **this is not a crash**.
- Other VR games still work fine.

## Root cause

Two independent faults, stacked. Fixing either one alone does nothing — the second one still blocks.

### Fault 1 — VDXR does not speak OpenXR 1.1

SynthRiders 2.16.7 is built on Unity 6000.3.13f1 with OpenXR XR Plugin 1.16, which asks for
**OpenXR API version 1.1.53**. Virtual Desktop's own runtime, VDXR v1.0.10, implements OpenXR **1.0**
and refuses outright. From `C:\ProgramData\Virtual Desktop\OpenXR.log`:

````text
VirtualDesktopOpenXR - v1.0.10 (C:\Program Files\Virtual Desktop Streamer\OpenXR)
Application: SynthRiders (SynthRiders.exe); Engine: Unity
Application request API version 1.1.53
xrCreateInstance failed with XR_ERROR_API_VERSION_UNSUPPORTED
````

SteamVR's runtime is *also* an OpenXR 1.0 runtime, but it negotiates properly — the game falls back and
gets its instance at **1.0.34**. VDXR just hard-fails.

### Fault 2 — LIV's OpenXR API layer breaks instance creation

With the runtime forced to SteamVR, `xrCreateInstance` **still** failed. The culprit is LIV's implicit
OpenXR API layer, `XR_LIV_stabilizer`, registered under
`HKCU\SOFTWARE\Khronos\OpenXR\1\ApiLayers\Implicit`.

Implicit API layers are injected into *every* OpenXR application whether it asks for them or not, so one
broken layer takes down every OpenXR title on the machine.

The A/B, both through the normal Steam launch path, both on SteamVR's runtime:

| LIV layer | `Available Layers` | Result |
|---|---|---|
| enabled | 2 | `xrCreateInstance: XR_ERROR_LAYER_INVALID`, no session |
| **disabled** | 1 | **`XR_SESSION_STATE_FOCUSED`** — running in the headset |

Virtual Desktop's other layer, `XR_APILAYER_VIRTUALDESKTOP_oculus_compatibility`, is **innocent** — it
stays loaded in the working configuration.

### Why it looked so confusing

- **Unity's error message points at the wrong thing.** Unity logs
  `xrCreateInstance: XR_ERROR_LAYER_INVALID` for fault 1 as well, even though the runtime's own log says
  `XR_ERROR_API_VERSION_UNSUPPORTED`. Trust the **runtime's** log over the engine's.
- **Fault 1 masks fault 2.** While VDXR held the runtime, the LIV layer never got a chance to fail, so
  fixing only the runtime looks like it changed nothing.
- **OpenVR titles are unaffected**, because they never touch the OpenXR runtime or its API layers. VRChat
  kept working the whole time (`StartVRSDK: OpenVRLoader`), which made it feel like "VR works, this one
  game is broken".

## The fix

Both parts are needed.

### 1. Force SteamVR as the OpenXR runtime

Setting the registry key is **not enough** — Virtual Desktop rewrites
`HKLM\SOFTWARE\Khronos\OpenXR\1\ActiveRuntime` back to VDXR within seconds of starting or reconnecting.
Use the loader-level override instead, which per the Khronos loader spec bypasses the registry entirely:

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

### 2. Disable LIV's OpenXR stabilizer layer

`1` = disabled, `0` = enabled. This lives in **HKCU**, so no elevation is needed:

````powershell
Set-ItemProperty 'HKCU:\SOFTWARE\Khronos\OpenXR\1\ApiLayers\Implicit' `
  -Name 'C:\Program Files (x86)\Steam\steamapps\common\LIV\Resources\OpenXR\Stabilizer\manifest.json' `
  -Value 1 -Type DWord
````

?> **This does not break LIV capture in SynthRiders.** SynthRiders ships the LIV SDK natively — the
working run still logs `LIV: Created capture protocol: Bridge` and
`LIV: instance created successfully`. `XR_LIV_stabilizer` is LIV's *First Person Stabilizer* injector for
games **without** native LIV support. If that feature is needed elsewhere, flip the value back to `0`.

!> LIV may re-register its layer (value back to `0`) after a LIV update. If SynthRiders breaks again out
of nowhere, check this value first — `Check-VRStack.ps1` prints it.

### Why the obvious fixes do nothing

| Attempt | Why it can't work |
|---|---|
| Reinstall the game | Both faults are outside the game files |
| Steam file integrity verification | Same |
| Switching version branches (`open-beta`, etc.) | Same |
| Launch option `-vrmode openvr` | Legacy Unity VR flag; Unity XR Plugin Management / OpenXR ignores it |
| SteamVR → "set SteamVR as OpenXR runtime" button | Crashed with `Exception c0000005` and never wrote the setting |
| Writing `ActiveRuntime` in the registry | Virtual Desktop overwrites it on connect |
| Setting `ActiveRuntime` from a non-elevated shell | `HKLM` needs elevation — fails quietly enough to look like it worked |

## The logs that diagnose this whole class of problem

Nothing here needs the headset on. Run `Check-VRStack.ps1` (sitting next to this note) to get a verdict
from all of them at once.

| Log | What it tells you |
|---|---|
| `C:\ProgramData\Virtual Desktop\OpenXR.log` | **The honest one.** VDXR's own record of the last instance request: which app, which API version, and the real error. Overwritten per launch |
| `%USERPROFILE%\AppData\LocalLow\Kluge Interactive\SynthRiders\Player.log` | Unity's log. The decisive line is `Available Layers: (n)` — compare a working run against a broken one. `Player-prev.log` is the run before |
| `C:\Program Files (x86)\Steam\logs\xrclient_SynthRiders.txt` | Written **only** when an app reaches *SteamVR's* OpenXR runtime. A fresh timestamp is the objective pass signal |
| `C:\Program Files (x86)\Steam\logs\vrserver.txt` | `AppTransition: Aborting external launch because of timeout after 60s` — this line *is* the stuck placeholder overlay |

?> Two that look useful but aren't: `vrclient_SynthRiders.txt` is the **OpenVR** path and this game never
uses it, and `SynthRidersUC\AppLog.txt` stopped being written by the current build. Don't read anything
into their timestamps.

### Reading a Unity OpenXR log

The success/failure signature is unmistakable once you know where to look:

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

`XR_SESSION_STATE_FOCUSED` is the goal — that means the game is rendering in the headset and has input
focus.

?> **Beware double instances when testing.** Launching `SynthRiders.exe` directly makes Steam relaunch it,
so two processes run and `Player.log` rotates under you — which makes results look random. Dropping a
`steam_appid.txt` containing `885000` next to the exe stops the relaunch and gives clean single-instance
tests. Remove it afterwards.

## Environment this was diagnosed on

| Item | Value |
|---|---|
| Game | Synth Riders 2.16.7, AppID 885000, buildid 24297306, branch `open-beta` |
| Engine | Unity 6000.3.13f1, IL2CPP, OpenXR XR Plugin 1.16 (requests OpenXR **1.1.53**) |
| Headset | Meta Quest 3 (SteamVR mislabels it "Oculus Quest2" — Virtual Desktop's shim naming, harmless) |
| Link | Virtual Desktop Streamer 1.34.18, wireless, SteamVR mode |
| VDXR | v1.0.10 — **OpenXR 1.0 only** |
| SteamVR | 2.16.7 (OpenXR 1.0.34) |
| Overlays | LIV 2.1.0, fpsVR, OVR Toolkit, OpenVR-SpaceCalibrator, OyasumiVR |
| GPU | RTX 4090, driver 32.0.16.1047, HAGS on |

!> Virtual Desktop Streamer 1.34.18 was the current release, so "just update Virtual Desktop" was not an
option. Upstream [VDXR](https://github.com/mbucchia/VirtualDesktop-OpenXR) does implement OpenXR 1.1, so a
later Streamer build should make fault 1 disappear on its own — at which point the `XR_RUNTIME_JSON`
override can be dropped. Fault 2 is independent of that.

?> Other software known to grab the OpenXR `ActiveRuntime` key: the Oculus PC app, Meta Quest Developer
Hub, and Virtual Desktop — especially right after an update. If an OpenXR game suddenly stops working,
check that key and the implicit layer list first.

## Loose end

`xrEndFrame: XR_ERROR_HANDLE_INVALID` shows up periodically during play. It does not stop the game — a
full run played fine — and it coincides with session state changes (headset off/on, dashboard). Noted
here in case it turns into something.
