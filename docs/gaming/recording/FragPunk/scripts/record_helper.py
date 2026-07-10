# /// script
# requires-python = ">=3.11"
# dependencies = ["obsws-python>=1.7"]
# ///
"""record-helper — interactive CLI for FragPunk multi-POV replay-pass recording.

Drives OBS (start/stop recording via obs-websocket v5), renames the resulting files
to the r{round}_{moment}_{pov}.mkv scheme and sorts them into sessions/{date}/ folders.

Anti-cheat safety: this tool talks to OBS and the filesystem ONLY. All in-game work
(opening the replay, scrubbing, switching cameras) stays manual, on purpose.

Usage (on the gaming PC, OBS running with the WebSocket server enabled):

    uv run record_helper.py                 # interactive replay-pass session
    uv run record_helper.py --moments       # list replay-buffer saves = highlight log
    uv run record_helper.py --password ***  # if the WebSocket server has auth enabled

Environment variables: OBS_WS_HOST, OBS_WS_PORT, OBS_WS_PASSWORD.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import sys
import time
from datetime import datetime
from pathlib import Path

DEFAULT_SESSIONS_ROOT = Path.home() / "Videos" / "FragPunk" / "sessions"
POV_SEQUENCE = ("mypov", "enemypov")  # extra angles prompted afterwards
SYNC_REMINDER = (
    "  Sync discipline: start EVERY pass of this moment at the SAME replay-clock time\n"
    "  (e.g. exactly 1:32). That is what makes the clips stack frame-aligned in Resolve."
)


def sanitize(label: str) -> str:
    label = label.strip().lower().replace(" ", "-")
    label = re.sub(r"[^a-z0-9-]", "", label)
    return re.sub(r"-+", "-", label).strip("-")


def unique_path(path: Path) -> Path:
    if not path.exists():
        return path
    for i in range(2, 100):
        candidate = path.with_stem(f"{path.stem}-{i}")
        if not candidate.exists():
            return candidate
    raise RuntimeError(f"too many name collisions for {path}")


def connect(host: str, port: int, password: str):
    try:
        import obsws_python as obs
    except ImportError:
        sys.exit("obsws-python missing. Run via 'uv run record_helper.py' or 'pip install obsws-python'.")
    try:
        client = obs.ReqClient(host=host, port=port, password=password or None, timeout=5)
        version = client.get_version()
        print(f"Connected: OBS {version.obs_version}, obs-websocket {version.obs_web_socket_version}")
        return client
    except Exception as exc:  # connection refused, auth failure, timeout
        print(f"Could not connect to OBS at {host}:{port} — {exc}\n", file=sys.stderr)
        print(
            "Checklist:\n"
            "  1. Is OBS running (as Administrator)?\n"
            "  2. OBS: Tools -> WebSocket Server Settings -> 'Enable WebSocket server' checked?\n"
            "  3. Port/password match? (defaults: 4455, no auth; use --password / OBS_WS_PASSWORD)\n"
            "  4. Full environment check: scripts/verify-environment.ps1",
            file=sys.stderr,
        )
        sys.exit(1)


def wait_for_file(path: Path, timeout: float = 10.0) -> bool:
    """Wait until the recording file exists and its size is stable (OBS finished writing)."""
    deadline = time.monotonic() + timeout
    last_size = -1
    while time.monotonic() < deadline:
        if path.exists():
            size = path.stat().st_size
            if size > 0 and size == last_size:
                return True
            last_size = size
        time.sleep(0.5)
    return path.exists()


def record_pass(client, session_dir: Path, round_no: int, moment: str, pov: str) -> Path | None:
    """One replay pass: operator scrubs manually, Enter starts, Enter stops."""
    status = client.get_record_status()
    if status.output_active:
        answer = input("OBS is already recording. Stop that recording first? [Y/n] ").strip().lower()
        if answer in ("", "y", "yes"):
            client.stop_record()
            time.sleep(1)
        else:
            print("Skipping this pass.")
            return None

    print(f"\n--- r{round_no} '{moment}' — pass: {pov} ---")
    print(SYNC_REMINDER)
    input(f"  Scrub the replay into position, then press Enter to START recording ({pov})... ")
    client.start_record()
    started = time.monotonic()
    input("  RECORDING — press Enter to STOP... ")
    response = client.stop_record()
    elapsed = time.monotonic() - started

    output_path = Path(response.output_path)
    if not wait_for_file(output_path):
        print(f"  WARNING: OBS reported {output_path} but the file never settled. Check manually.", file=sys.stderr)
        return None

    target = unique_path(session_dir / f"r{round_no}_{moment}_{pov}{output_path.suffix}")
    shutil.move(str(output_path), str(target))
    print(f"  saved: {target.name}  ({elapsed:.1f}s, {target.stat().st_size / 1_048_576:.0f} MB)")

    manifest = session_dir / "manifest.jsonl"
    with manifest.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps({
            "ts": datetime.now().isoformat(timespec="seconds"),
            "round": round_no,
            "moment": moment,
            "pov": pov,
            "file": target.name,
            "seconds": round(elapsed, 1),
        }) + "\n")
    return target


def interactive_session(client, sessions_root: Path) -> None:
    session_dir = sessions_root / datetime.now().strftime("%Y-%m-%d")
    session_dir.mkdir(parents=True, exist_ok=True)
    print(f"Session folder: {session_dir}")
    print("Open the FragPunk replay now (replays may expire — record same-day).\n")

    while True:
        raw = input("Round number (or q to quit): ").strip().lower()
        if raw in ("q", "quit", "exit"):
            break
        if not raw.isdigit():
            print("  Enter a number, e.g. 7.")
            continue
        round_no = int(raw)

        moment = sanitize(input("Moment label (e.g. ace, clutch, ninja): "))
        if not moment:
            print("  Empty label, skipping.")
            continue

        for pov in POV_SEQUENCE:
            record_pass(client, session_dir, round_no, moment, pov)

        while True:
            extra = input("Extra angle? Label it (e.g. freecam) or press Enter to finish this moment: ").strip()
            if not extra:
                break
            pov = sanitize(extra)
            if pov:
                record_pass(client, session_dir, round_no, moment, pov)

        print(f"Moment r{round_no}_{moment} done.\n")

    print(f"\nSession complete. Next: postprocess.ps1 -SessionDir \"{session_dir}\"")


def list_moments(client) -> None:
    """List replay-buffer saves in the OBS record dir — the highlight log of the last matches."""
    record_dir = Path(client.get_record_directory().record_directory)
    saves = sorted(record_dir.glob("Replay*"), key=lambda p: p.stat().st_mtime)
    if not saves:
        print(f"No replay-buffer saves found in {record_dir}.")
        print("Did you bind the Save-Replay hotkey and hit it during play? (obs/README.md step 6)")
        return
    print(f"Replay-buffer markers in {record_dir}:")
    for save in saves:
        stamp = datetime.fromtimestamp(save.stat().st_mtime).strftime("%H:%M:%S")
        print(f"  {stamp}  {save.name}")
    print("\nMatch these times against the match history to find the rounds to re-record.")


def main() -> None:
    parser = argparse.ArgumentParser(description="FragPunk replay-pass recording helper (OBS via obs-websocket).")
    parser.add_argument("--host", default=os.getenv("OBS_WS_HOST", "127.0.0.1"))
    parser.add_argument("--port", type=int, default=int(os.getenv("OBS_WS_PORT", "4455")))
    parser.add_argument("--password", default=os.getenv("OBS_WS_PASSWORD", ""))
    parser.add_argument("--sessions-root", type=Path, default=DEFAULT_SESSIONS_ROOT,
                        help=f"where sessions/{{date}}/ folders live (default: {DEFAULT_SESSIONS_ROOT})")
    parser.add_argument("--moments", action="store_true",
                        help="list replay-buffer saves (highlight timestamps) and exit")
    args = parser.parse_args()

    client = connect(args.host, args.port, args.password)
    try:
        if args.moments:
            list_moments(client)
        else:
            interactive_session(client, args.sessions_root)
    except (KeyboardInterrupt, EOFError):
        status = client.get_record_status()
        if status.output_active:
            print("\nInterrupted while recording — stopping OBS recording.", file=sys.stderr)
            client.stop_record()
        else:
            print("\nInterrupted.", file=sys.stderr)
        sys.exit(130)


if __name__ == "__main__":
    main()
