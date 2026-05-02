#!/usr/bin/env python3
"""Connect an Android device via WiFi debugging automatically.

Usage:
  python3 scripts/wifi_debug_qr.py          # auto-detect IP from USB-connected device
  python3 scripts/wifi_debug_qr.py 192.168.1.42  # explicit IP
"""

import subprocess
import sys


def ensure_qrcode():
    try:
        import qrcode
        return qrcode
    except ImportError:
        print("Installing qrcode library (user install)...")
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "qrcode", "--user", "-q"],
            capture_output=True,
        )
        if result.returncode != 0:
            # Homebrew Python with externally-managed env — try --break-system-packages
            subprocess.check_call(
                [sys.executable, "-m", "pip", "install", "qrcode",
                 "--break-system-packages", "-q"],
            )
        import importlib
        import site
        importlib.invalidate_caches()
        # Ensure user site-packages is on path after --user install
        for p in site.getusersitepackages() if isinstance(site.getusersitepackages(), list) else [site.getusersitepackages()]:
            if p not in sys.path:
                sys.path.insert(0, p)
        import qrcode
        return qrcode


def get_device_ip_via_adb():
    """Return the WiFi IP of the first connected adb device."""
    # Try wlan0 first, then en0-style names used on some devices
    for iface in ("wlan0", "wlan1", "eth0"):
        try:
            out = subprocess.check_output(
                ["adb", "shell", f"ip -f inet addr show {iface}"],
                stderr=subprocess.DEVNULL,
                text=True,
            )
            for line in out.splitlines():
                line = line.strip()
                if line.startswith("inet "):
                    ip = line.split()[1].split("/")[0]
                    return ip
        except subprocess.CalledProcessError:
            continue
    return None


def enable_tcpip(port=5555):
    try:
        subprocess.check_call(
            ["adb", "tcpip", str(port)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        pass


def restart_adb_server():
    subprocess.run(["adb", "kill-server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    subprocess.run(["adb", "start-server"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def adb_connect(ip, port=5555):
    """Restart adb server (needed after USB→TCP switch) then connect."""
    import time
    restart_adb_server()
    time.sleep(1)
    out = subprocess.check_output(
        ["adb", "connect", f"{ip}:{port}"],
        stderr=subprocess.STDOUT,
        text=True,
    ).strip()
    success = "connected" in out.lower() and "unable" not in out.lower()
    return success, out


def qr_to_text(qr):
    """Render a QRCode object as half-block Unicode characters (2 rows → 1 line)."""
    # qr.modules is a list of lists of booleans; True = dark module
    modules = qr.modules
    size = len(modules)
    border = qr.border

    # Add border padding as False rows/cols
    pad = [[False] * (size + border * 2)]
    grid = (
        pad * border
        + [[False] * border + row + [False] * border for row in modules]
        + pad * border
    )
    full_size = len(grid)

    lines = []
    for row in range(0, full_size, 2):
        line = ""
        for col in range(len(grid[row])):
            top = grid[row][col]
            bot = grid[row + 1][col] if row + 1 < full_size else False
            if top and bot:
                line += "█"
            elif top:
                line += "▀"
            elif bot:
                line += "▄"
            else:
                line += " "
        lines.append(line)
    return "\n".join(lines)


def main():
    port = 5555

    if len(sys.argv) > 1:
        ip = sys.argv[1]
    else:
        print("Detecting device IP via adb...")
        ip = get_device_ip_via_adb()
        if ip:
            enable_tcpip(port)
        if not ip:
            print(
                "Could not detect device IP.\n"
                "Make sure a device is connected via USB with USB debugging enabled,\n"
                "or pass the IP explicitly: python3 scripts/wifi_debug_qr.py <ip>"
            )
            sys.exit(1)

    print(f"\nDevice IP : {ip}:{port}")
    print("Connecting via WiFi...")

    success, output = adb_connect(ip, port)
    if success:
        print(f"Connected: {output}")
    else:
        print(f"Failed: {output}")
        sys.exit(1)

    qrcode = ensure_qrcode()
    qr = qrcode.QRCode(border=1)
    qr.add_data(f"adb connect {ip}:{port}")
    qr.make(fit=True)

    print()
    print(qr_to_text(qr))
    print(f"\nQR for reconnecting: adb connect {ip}:{port}")


if __name__ == "__main__":
    main()
