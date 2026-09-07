#!/usr/bin/env bash
# Collect, read-only, everything on the Windows volume that could hold this sensor's
# pre-shared key -- before considering anything that overwrites that key.
#
# Why this exists, and why it is not the earlier find-psk.sh:
#
#   The sensor stores only sha256(PSK). Windows writes a random key per install and keeps
#   its own copy somewhere on the Windows side. If that copy can be read, Linux can use the
#   sensor with no re-keying at all, and Windows Hello keeps working. If it cannot, the only
#   remaining option overwrites the key, and that is a one-way door.
#
#   find-psk.sh only looked for a plaintext 32-byte literal, and only under System32. On a
#   sibling ASUS machine with the same sensor, an exhaustive plaintext scan over 111 MB of
#   exactly these files found nothing, so that search is close to settled already. What it
#   never covered is the vendor's own data directory and the wrapped-key candidates, which
#   is where a key recovered successfully on a related Goodix sensor actually lived.
#
# STRICTLY READ-ONLY. The volume is mounted `ro`. Nothing is written to it, no journal is
# replayed, and Windows is not modified in any way. Everything collected is copied out to a
# private directory for offline inspection.
set -uo pipefail

PART=${PART:-/dev/nvme0n1p2}
MNT=$(mktemp -d /tmp/win-ro.XXXXXX)
OUT=${OUT:-$HOME/goodix-psk-evidence}
OWNER=${SUDO_USER:-$USER}

die() { echo "error: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "must run as root (mounting a partition). Try: sudo $0"

cleanup() {
  if mountpoint -q "$MNT"; then umount "$MNT" && echo "unmounted $MNT"; fi
  rmdir "$MNT" 2>/dev/null
}
trap cleanup EXIT

# A BitLocker volume would need its recovery key before any of this is possible. Check
# rather than assume: the signature sits in the volume header.
if head -c 16 "$PART" | grep -qa 'FVE-FS-'; then
  die "$PART is BitLocker-encrypted; unlock it first (this script will not touch it)"
fi

echo "mounting $PART read-only at $MNT"
mount -t ntfs3 -o ro "$PART" "$MNT" 2>/dev/null \
  || mount -o ro "$PART" "$MNT" \
  || die "could not mount $PART read-only"

mkdir -p "$OUT"
chmod 700 "$OUT"

copy_out() { # <source-relative-to-C:> <destination-subdir>
  local src="$MNT/$1" dst="$OUT/$2"
  [[ -e $src ]] || { echo "  absent: C:/$1"; return 1; }
  mkdir -p "$dst"
  cp -a --no-preserve=ownership "$src" "$dst/" 2>/dev/null \
    && echo "  copied: C:/$1" \
    || echo "  FAILED to copy: C:/$1"
}

echo
echo "== 1. The vendor's own data directory =="
# This is the directory that mattered on a related Goodix sensor, where the host-side key
# turned out to live in a cache file. Its contents vary by driver version, so list before
# copying rather than guessing filenames.
if [[ -d $MNT/ProgramData/Goodix ]]; then
  ls -la "$MNT/ProgramData/Goodix/" | sed 's/^/  /'
  mkdir -p "$OUT/ProgramData-Goodix"
  find "$MNT/ProgramData/Goodix" -maxdepth 2 -type f -size -64M \
    -exec cp -a --no-preserve=ownership {} "$OUT/ProgramData-Goodix/" \; 2>/dev/null
  echo "  -> copied $(find "$OUT/ProgramData-Goodix" -type f | wc -l) files"
else
  echo "  absent: C:/ProgramData/Goodix  (nothing to recover from here)"
fi

echo
echo "== 2. Registry hives =="
# SYSTEM and SECURITY together yield the machine-scope key material, which needs no Windows
# password. SOFTWARE holds the per-sensor WinBio values.
for h in SYSTEM SECURITY SOFTWARE; do
  copy_out "Windows/System32/config/$h" hives
done

echo
echo "== 3. Machine-scope key protection state =="
# Machine scope can be unwrapped entirely offline. User scope cannot, without that
# account's Windows password, so the two are worth telling apart early.
copy_out "Windows/System32/Microsoft/Protect/S-1-5-18" dpapi-machine

echo
echo "== 4. The vendor driver binary =="
# Worth having regardless of how this goes: it is the only known source of the newer
# firmware build, which exists nowhere publicly. One file, and it stops the Windows install
# from being load-bearing later.
found_dll=0
while IFS= read -r dll; do
  mkdir -p "$OUT/driver"
  cp -a --no-preserve=ownership "$dll" "$OUT/driver/" 2>/dev/null && {
    echo "  copied: ${dll#$MNT}"
    found_dll=1
  }
done < <(find "$MNT/Windows/System32/DriverStore/FileRepository" -maxdepth 2 \
           \( -iname 'wbdi*.dll' -o -iname 'goodix*.dll' -o -iname 'gdix*.dll' \) 2>/dev/null)
[[ $found_dll -eq 1 ]] || echo "  no vendor driver DLL found under DriverStore"

echo
echo "== 5. Fingerprint template store (for completeness, not for the key) =="
copy_out "Windows/System32/WinBioDatabase" winbio

echo
chown -R "$OWNER" "$OUT" 2>/dev/null
echo "collected into $OUT (owned by $OWNER, mode 0700)"
echo "total: $(du -sh "$OUT" 2>/dev/null | cut -f1)"
echo
echo "next, with no root and nothing mounted:"
echo "  python3 docs/fingerprint/tools/check-psk-candidates.py $OUT"
