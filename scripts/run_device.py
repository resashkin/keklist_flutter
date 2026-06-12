#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent


def get_devices():
    result = subprocess.run(
        ["fvm", "flutter", "devices", "--machine"],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


def find_real_device(devices):
    for d in devices:
        platform = d.get("targetPlatform", "")
        is_emulator = d.get("emulator", True)
        is_desktop = platform in ("darwin", "linux-x64", "windows-x64")
        is_web = "web" in platform
        if not is_emulator and not is_desktop and not is_web:
            return d
    return None


def main():
    devices = get_devices()
    device = find_real_device(devices)

    if not device:
        print("No real device found. Connect a device via cable and try again.")
        sys.exit(1)

    name = device.get("name", device["id"])
    device_id = device["id"]
    print(f"▶ Building on: {name} ({device_id})")

    mode = sys.argv[1] if len(sys.argv) > 1 else "--profile"
    subprocess.run(
        ["fvm", "flutter", "run", mode, "-d", device_id],
        cwd=PROJECT_ROOT,
    )


if __name__ == "__main__":
    main()
