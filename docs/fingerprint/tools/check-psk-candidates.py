#!/usr/bin/env python3
"""Decide, offline, whether this sensor's pre-shared key can be recovered from Windows.

Run after collect-windows-psk-evidence.sh. Needs no root and touches no device.

Two questions are answered:

  1. Is the key sitting somewhere as a plain 32-byte value? Every 32-byte window of every
     collected file is hashed and compared against what the sensor reports. A hit ends the
     whole problem: the key can simply be handed to the driver, Windows Hello keeps working,
     and nothing is overwritten.

  2. If not, is there a wrapped-key candidate worth pursuing, and is it wrapped at machine
     scope or user scope? Machine scope can be unwrapped offline from the collected hives.
     User scope needs that account's Windows password, which is a different proposition.

A negative result here is not proof the key is absent from Windows. It is proof it is not
present in the clear in the places worth looking, which is the question that decides whether
to move on to overwriting the key.
"""
import argparse
import hashlib
import pathlib
import struct
import sys

# What the sensor in this laptop reports. Read it from the driver's own error message, which
# now prints both digests, or pass --hash to check a different unit.
DEFAULT_DEVICE_HASH = "163ec2b1470b66fc7c2ec87822f9a82a1b4b17ce867f3c1784400c58461907bb"

# A Windows DPAPI blob opens with a version word and this provider identifier. Finding it is
# what distinguishes "an opaque binary file" from "a wrapped key we could name a price for".
DPAPI_PROVIDER = bytes.fromhex("d08c9ddf0115d1118c7a00c04fc297eb")

KEY_LEN = 32
MAX_SCAN_BYTES = 512 * 1024 * 1024


def scan_for_preimage(path: pathlib.Path, target: bytes):
    """Report any 32-byte window whose sha256 is the digest the sensor reports."""
    try:
        data = path.read_bytes()
    except (OSError, MemoryError):
        return [], 0
    hits = []
    for i in range(len(data) - KEY_LEN + 1):
        if hashlib.sha256(data[i:i + KEY_LEN]).digest() == target:
            hits.append((i, data[i:i + KEY_LEN].hex()))
    return hits, len(data)


def find_dpapi_blobs(path: pathlib.Path):
    """Locate DPAPI blobs and name the master key each one is wrapped under."""
    try:
        data = path.read_bytes()
    except (OSError, MemoryError):
        return []
    out = []
    start = 0
    while True:
        i = data.find(DPAPI_PROVIDER, start)
        if i < 0:
            break
        start = i + 1
        # Layout after the provider identifier is a 4-byte master-key version, then the
        # master-key identifier itself, as a GUID in Windows' mixed endianness.
        g = data[i + 20:i + 36]
        if len(g) < 16:
            continue
        try:
            d1, d2, d3 = struct.unpack("<IHH", g[:8])
        except struct.error:
            continue
        guid = f"{d1:08x}-{d2:04x}-{d3:04x}-{g[8:10].hex()}-{g[10:16].hex()}"
        out.append((i, guid))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("evidence_dir", type=pathlib.Path)
    ap.add_argument("--hash", default=DEFAULT_DEVICE_HASH,
                    help="the digest the sensor reports")
    args = ap.parse_args()

    if not args.evidence_dir.is_dir():
        sys.exit(f"not a directory: {args.evidence_dir}")

    try:
        target = bytes.fromhex(args.hash)
    except ValueError:
        sys.exit("--hash must be hex")
    if len(target) != 32:
        sys.exit("--hash must be a 32-byte sha256 digest")

    files = sorted(p for p in args.evidence_dir.rglob("*") if p.is_file())
    if not files:
        sys.exit(f"no files under {args.evidence_dir}; did the collection step run?")

    print(f"looking for a key whose sha256 is {args.hash}")
    print(f"across {len(files)} files\n")

    print("== Question 1: is the key present in the clear? ==")
    hits = []
    scanned = 0
    skipped = []
    for p in files:
        if p.stat().st_size > MAX_SCAN_BYTES:
            skipped.append(p)
            continue
        found, size = scan_for_preimage(p, target)
        scanned += size
        for offset, key in found:
            hits.append((p, offset, key))
            print(f"\n  *** FOUND ***")
            print(f"  file  : {p}")
            print(f"  offset: {offset} (0x{offset:x})")
            print(f"  key   : {key}\n")

    for p in skipped:
        print(f"  skipped, too large to window: {p} ({p.stat().st_size} bytes)")
    print(f"  scanned {scanned / 1e6:.1f} MB")

    if hits:
        print("\n  This is the good outcome. The sensor can be used as-is, with no")
        print("  re-keying and no effect on Windows Hello. Supply the key to the driver:")
        print(f"    LIBFPRINT_GOODIXTLS_PSK_HEX={hits[0][2]}")
        print("  Store it root-owned and 0600, not in the dotfiles repo.")
        return 0

    print("  no plaintext key found\n")

    print("== Question 2: is there a wrapped-key candidate? ==")
    machine_keys = {
        p.name.lower()
        for p in (args.evidence_dir / "dpapi-machine").rglob("*")
        if p.is_file() and len(p.name) == 36
    }
    if machine_keys:
        print(f"  machine-scope master keys collected: {len(machine_keys)}")
    else:
        print("  no machine-scope master keys collected")

    any_blob = False
    for p in files:
        if p.stat().st_size > MAX_SCAN_BYTES:
            continue
        for offset, guid in find_dpapi_blobs(p):
            any_blob = True
            scope = "MACHINE" if guid.lower() in machine_keys else "user or unknown"
            print(f"  {p.name} @ {offset}: wrapped under {guid} -> {scope} scope")

    if not any_blob:
        print("  none found")

    print("\n== What this means ==")
    if not any_blob:
        print("  Nothing on the Windows side holds this key in a form reachable from here.")
        print("  Recovering it is not a live option; the remaining route replaces it.")
    else:
        print("  A wrapped candidate exists. Machine scope can be unwrapped offline from the")
        print("  collected hives with impacket's dpapi tooling. User scope needs that")
        print("  account's Windows password. Note that a wrapped blob under the WinBio tree")
        print("  is more likely the template store's own key than the sensor key, so")
        print("  confirm what it is before treating this as a route.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
