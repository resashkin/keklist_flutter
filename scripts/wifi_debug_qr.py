#!/usr/bin/env python3
"""Connect an Android device via WiFi debugging automatically.

Usage:
  python3 scripts/wifi_debug_qr.py          # auto-detect IP from USB-connected device
  python3 scripts/wifi_debug_qr.py 192.168.1.42  # explicit IP

If no USB device is detected, generates a QR code in the
WIFI:T:ADB;S:<service>;P:<password>;; format that Android/Samsung
wireless-debugging can scan directly (Developer Options > Wireless
debugging > Pair device with QR code).  Advertises the pairing service
over mDNS (dns-sd on macOS, avahi on Linux) so the device can find the
host automatically.
"""

import random
import socket
import string
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


def get_local_ip():
    """Best-effort: return this machine's LAN IP."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as s:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
    except Exception:
        return "0.0.0.0"


def _random_service_name():
    return "studio-" + "".join(random.choices(string.ascii_lowercase + string.digits, k=8))


def _random_pairing_code():
    return "".join(random.choices(string.digits, k=6))


def _free_port():
    with socket.socket() as s:
        s.bind(("", 0))
        return s.getsockname()[1]


def _advertise_mdns(service_name, port):
    """Advertise _adb-tls-pairing._tcp via dns-sd (macOS) or avahi (Linux)."""
    try:
        return subprocess.Popen(
            ["dns-sd", "-R", service_name, "_adb-tls-pairing._tcp", ".", str(port)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass
    try:
        return subprocess.Popen(
            ["avahi-publish-service", service_name, "_adb-tls-pairing._tcp", str(port)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        pass
    return None


def print_no_device_qr(_connect_port: int):
    """Show ADB wireless pairing QR (WIFI:T:ADB format) when no USB device is found."""
    local_ip = get_local_ip()
    qrcode_lib = ensure_qrcode()

    service_name = _random_service_name()
    pairing_code = _random_pairing_code()
    pairing_port = _free_port()

    # Android/Samsung wireless-debugging QR format
    qr_data = f"WIFI:T:ADB;S:{service_name};P:{pairing_code};;"

    print(f"\nNo USB device detected.")
    print(f"Machine IP : {local_ip}")
    print(f"Pairing port: {pairing_port}\n")

    mdns = _advertise_mdns(service_name, pairing_port)
    if mdns:
        print(f"mDNS service advertised: {service_name}._adb-tls-pairing._tcp\n")

    qr = qrcode_lib.QRCode(border=1)
    qr.add_data(qr_data)
    qr.make(fit=True)
    print(qr_to_text(qr))

    print(f"\nScan the QR above:")
    print(f"  Developer Options > Wireless debugging > Pair device with QR code")
    print(f"\nManual pairing alternative:")
    print(f"  1. Wireless debugging > Pair with pairing code")
    print(f"  2. Note the <device-ip>:<pair-port> shown on screen")
    print(f"  3. adb pair <device-ip>:<pair-port> {pairing_code}")
    print(f"  4. adb connect <device-ip>:5555")

    if mdns:
        try:
            print("\nListening for connection (Ctrl+C to cancel)...")
            mdns.wait()
        except KeyboardInterrupt:
            mdns.terminate()
            print()


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
            print_no_device_qr(port)
            sys.exit(0)

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
