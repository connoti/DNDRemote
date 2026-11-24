#!/usr/bin/env python3
"""Check public TCP reachability for a RustDesk server."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import socket


def check_port(host: str, port: int, timeout: float) -> tuple[int, str | None]:
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return port, None
    except OSError as error:
        return port, str(error)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("host", help="RustDesk server DNS name or IP")
    parser.add_argument("--timeout", type=float, default=3, help="Seconds per connection")
    parser.add_argument("--ssh", action="store_true", help="Also check TCP 22")
    args = parser.parse_args()
    if not 0 < args.timeout < float("inf"):
        parser.error("--timeout must be a positive, finite number")

    ports = [21115, 21116, 21117, 21118, 21119]
    if args.ssh:
        ports.insert(0, 22)
    failed = False
    with ThreadPoolExecutor(max_workers=len(ports)) as executor:
        checks = [executor.submit(check_port, args.host, port, args.timeout) for port in ports]
        for check in checks:
            port, error = check.result()
            print(f"{args.host}:{port}/tcp {'open' if error is None else error}")
            failed |= error is not None
    return int(failed)


if __name__ == "__main__":
    raise SystemExit(main())
