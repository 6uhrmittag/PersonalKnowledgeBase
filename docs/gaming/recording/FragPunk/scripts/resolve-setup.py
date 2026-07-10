"""resolve-setup — create a vertical FragPunk project in DaVinci Resolve (CLAUDE.md §8.4).

Imports a record-helper session folder, groups clips by their r{round}_{moment} prefix
and creates one 1080x1920@60 timeline per highlight with the POVs stacked:
V1 = mypov, V2 = enemypov, V3+ = extra angles — aligned at frame 0, which is valid
because every replay pass was started at the same replay-clock time (sync-at-source).

Edition gate: external scripting needs Resolve STUDIO (plus Preferences -> System ->
General -> "External scripting using local"). On the FREE edition this script still
works when run from Resolve's built-in console. **This machine runs Resolve 21 Free
(verified 2026-07), so the console route is the way to run it here:**
    Workspace -> Console -> Py3, then:
    exec(open(r"<path>\resolve-setup.py").read())

External usage (Studio, Resolve running):
    python resolve-setup.py [--session <dir>] [--project <name>]

Defaults: newest session under %USERPROFILE%\\Videos\\FragPunk\\sessions,
project name FragPunk-{session date}.
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

DEFAULT_SESSIONS_ROOT = Path.home() / "Videos" / "FragPunk" / "sessions"
CLIP_PATTERN = re.compile(r"^r(?P<round>\d+)_(?P<moment>.+)_(?P<pov>[a-z0-9-]+)\.(mp4|mkv)$")
POV_ORDER = {"mypov": 0, "enemypov": 1}  # anything else sorts after, alphabetically

TIMELINE_SETTINGS = {
    "timelineResolutionWidth": "1080",
    "timelineResolutionHeight": "1920",
    "timelineFrameRate": "60",
}


def get_resolve():
    """Return the Resolve app object, or exit with edition/setup guidance."""
    # Case 1: running inside Resolve's own console — `resolve` is pre-injected.
    injected = globals().get("resolve")
    if injected is not None:
        return injected

    # Case 2: external — locate the scripting module (Studio only).
    api_dir = os.getenv(
        "RESOLVE_SCRIPT_API",
        r"C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting",
    )
    os.environ.setdefault(
        "RESOLVE_SCRIPT_LIB",
        r"C:\Program Files\Blackmagic Design\DaVinci Resolve\fusionscript.dll",
    )
    modules = str(Path(api_dir) / "Modules")
    if modules not in sys.path:
        sys.path.append(modules)

    try:
        import DaVinciResolveScript as dvr
    except ImportError:
        sys.exit(
            f"DaVinciResolveScript module not found under {modules}.\n"
            "Check the Resolve install, or set RESOLVE_SCRIPT_API. "
            "Diagnosis: scripts/verify-environment.ps1"
        )

    app = dvr.scriptapp("Resolve")
    if app is None:
        sys.exit(
            "Could not attach to Resolve. Either it is not running, or external scripting "
            "is unavailable:\n"
            "  - FREE edition: scripting is console-only. Open Workspace -> Console -> Py3 "
            "inside Resolve and run:\n"
            f'      exec(open(r"{Path(__file__).resolve()}").read())\n'
            "  - STUDIO: enable Preferences -> System -> General -> "
            "'External scripting using local' and keep Resolve running."
        )
    return app


def find_session(sessions_root: Path, explicit: str | None) -> Path:
    if explicit:
        session = Path(explicit)
        if not session.is_dir():
            sys.exit(f"Session folder not found: {session}")
        return session
    candidates = sorted((p for p in sessions_root.iterdir() if p.is_dir()), reverse=True)
    if not candidates:
        sys.exit(f"No session folders under {sessions_root} — run record_helper.py first.")
    return candidates[0]


def collect_groups(session: Path) -> dict[str, list[Path]]:
    """Group clips by r{round}_{moment}; prefer .mp4 (remuxed) over the .mkv original."""
    best: dict[str, Path] = {}  # key: filename stem -> preferred file
    for file in session.iterdir():
        if not CLIP_PATTERN.match(file.name):
            continue
        stem = file.stem
        if stem not in best or file.suffix == ".mp4":
            best[stem] = file

    groups: dict[str, list[Path]] = {}
    for file in best.values():
        match = CLIP_PATTERN.match(file.name)
        key = f"r{match['round']}_{match['moment']}"
        groups.setdefault(key, []).append(file)

    for key, files in groups.items():
        files.sort(key=lambda f: (POV_ORDER.get(CLIP_PATTERN.match(f.name)["pov"], 99),
                                  CLIP_PATTERN.match(f.name)["pov"]))
    return dict(sorted(groups.items()))


def main() -> None:
    import argparse

    parser = argparse.ArgumentParser(description="Create a stacked multi-POV Resolve project from a session folder.")
    parser.add_argument("--session", help=f"session folder (default: newest under {DEFAULT_SESSIONS_ROOT})")
    parser.add_argument("--project", help="Resolve project name (default: FragPunk-{session folder name})")
    args, _ = parser.parse_known_args()  # tolerate Resolve-console leftovers in argv

    session = find_session(DEFAULT_SESSIONS_ROOT, args.session)
    groups = collect_groups(session)
    if not groups:
        sys.exit(f"No r{{round}}_{{moment}}_{{pov}} clips in {session} — nothing to do.")
    print(f"Session {session.name}: {len(groups)} highlight(s), "
          f"{sum(len(v) for v in groups.values())} clip(s).")

    resolve = get_resolve()
    manager = resolve.GetProjectManager()

    project_name = args.project or f"FragPunk-{session.name}"
    if manager.LoadProject(project_name):
        sys.exit(f"Project '{project_name}' already exists — refusing to touch it. "
                 "Pass --project <other name>.")
    project = manager.CreateProject(project_name)
    if not project:
        sys.exit(f"Could not create project '{project_name}'.")

    for key, value in TIMELINE_SETTINGS.items():
        if not project.SetSetting(key, value):
            print(f"  WARNING: could not set {key}={value} — fix manually in project settings.")

    media_pool = project.GetMediaPool()
    all_files = [str(f) for files in groups.values() for f in files]
    items = resolve.GetMediaStorage().AddItemListToMediaPool(all_files) or []
    by_name = {item.GetName(): item for item in items}
    if len(by_name) < len(all_files):
        missing = sorted(set(Path(f).name for f in all_files) - set(by_name))
        print(f"  WARNING: {len(missing)} clip(s) failed to import: {', '.join(missing)}")

    for key, files in groups.items():
        timeline = media_pool.CreateEmptyTimeline(key)
        if not timeline:
            print(f"  WARNING: could not create timeline '{key}', skipping.")
            continue
        clip_infos = []
        for track_index, file in enumerate(files, start=1):
            item = by_name.get(file.name)
            if item is None:
                continue
            clip_infos.append({"mediaPoolItem": item, "trackIndex": track_index, "recordFrame": 0})
        appended = media_pool.AppendToTimeline(clip_infos)
        povs = ", ".join(f"V{i + 1}={CLIP_PATTERN.match(f.name)['pov']}" for i, f in enumerate(files))
        status = "OK " if appended else "WARN (append failed — stack manually)"
        print(f"  {status} timeline {key}: {povs}")

    manager.SaveProject()
    print(f"\nProject '{project_name}' ready. In each timeline: V-tracks are pre-aligned at "
          "frame 0; toggle track visibility or blade between them for the POV swap.")


main()
