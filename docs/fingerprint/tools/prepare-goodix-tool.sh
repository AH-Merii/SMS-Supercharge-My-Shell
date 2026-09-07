#!/usr/bin/env bash
# Prepare a checkout of the community Goodix tool for re-keying this sensor.
#
# Nothing here touches the device. It clones the tool, proves the recovery firmware is
# present and correct BEFORE anything can erase the sensor, applies two fixes the tool
# needs, and builds a virtualenv.
#
# The two fixes, and why they are not optional:
#
#   1. read_otp() asks the sensor for zero bytes. The first payload byte is the requested
#      length and upstream sends 0x00, so the reply is empty and the tool dies with
#      "Invalid OTP" -- AFTER the erase, key write and reflash have all succeeded. Everyone
#      who runs this hits it and many read it as a failed flash. Do not work around it by
#      faking the OTP, which is the historical advice; two people report that produces a
#      reader that matches the wrong finger.
#
#   2. firmware_version() assumes the sensor acknowledges the command before answering. A
#      sensor provisioned by another operating system answers without that acknowledgement,
#      so the tool dies on its very first call, before the erase. The same sensor
#      acknowledges normally again once re-keyed, so the fix has to accept both shapes
#      rather than swapping one assumption for the other.
set -uo pipefail

DEST=${DEST:-$HOME/src/goodix-fp-dump}
FIRMWARE_SHA=6ff41957f387160c089559dffff6e8a26d1fa344d01bdaa6d62c5dab61883804
FIRMWARE_REL=firmware/52xd/GFUSB_GM168SEC_APP_10019.bin
BACKUP=$HOME/.local/share/goodix-firmware/GFUSB_GM168SEC_APP_10019.bin

die() { echo "error: $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "do NOT run this as root; only the re-keying run itself needs root"

if [[ -d $DEST/.git ]]; then
  echo "reusing existing checkout at $DEST"
else
  echo "cloning into $DEST"
  git clone --recurse-submodules \
    https://github.com/goodix-fp-linux-dev/goodix-fp-dump.git "$DEST" \
    || die "clone failed"
fi

cd "$DEST" || die "cannot enter $DEST"

# The tool erases the sensor's firmware one loop iteration BEFORE it ever opens the
# replacement image, and it opens that image by a relative path. A wrong directory or a
# clone without submodules therefore leaves the sensor with nothing to flash. Prove the
# image is here and correct now, while that is still a cheap thing to discover.
if [[ ! -f $FIRMWARE_REL ]]; then
  echo "recovery firmware missing; restoring from $BACKUP"
  [[ -f $BACKUP ]] || die "no firmware image, and no local backup at $BACKUP. Stop here: without it an erase is unrecoverable."
  mkdir -p "$(dirname "$FIRMWARE_REL")"
  cp "$BACKUP" "$FIRMWARE_REL"
fi

actual=$(sha256sum "$FIRMWARE_REL" | cut -d' ' -f1)
[[ $actual == "$FIRMWARE_SHA" ]] \
  || die "recovery firmware has the wrong hash: got $actual, want $FIRMWARE_SHA"
echo "recovery firmware verified: $FIRMWARE_REL ($(stat -c%s "$FIRMWARE_REL") bytes)"

python3 - <<'PY' || exit 1
import pathlib
import sys

path = pathlib.Path("goodix.py")
src = path.read_text()

# Fix 1: ask for the 64 OTP bytes the caller actually requires.
otp_before = '''        self.protocol.write(
            encode_message_pack(
                encode_message_protocol(b"\\x00\\x00", COMMAND_READ_OTP)))'''
otp_after = '''        self.protocol.write(
            encode_message_pack(
                encode_message_protocol(b"\\x40\\x00", COMMAND_READ_OTP)))'''

# Fix 2: accept a firmware-version reply with or without a preceding acknowledgement.
fw_before = '''        if isinstance(self.protocol, protocol.USBProtocol):
            check_ack(
                check_message_protocol(
                    check_message_pack(self.protocol.read()), COMMAND_ACK),
                COMMAND_FIRMWARE_VERSION)

        return check_message_protocol(
            check_message_pack(self.protocol.read()),
            COMMAND_FIRMWARE_VERSION).split(b"\\x00")[0].decode()'''
fw_after = '''        message = check_message_pack(self.protocol.read())

        if isinstance(self.protocol, protocol.USBProtocol):
            # Dispatch on the command byte instead of assuming an ack is there. A sensor
            # provisioned by another OS answers this one without an ack; the same sensor
            # acks normally again once re-keyed, so both shapes have to work.
            if message[0] == COMMAND_ACK:
                check_ack(
                    check_message_protocol(message, COMMAND_ACK),
                    COMMAND_FIRMWARE_VERSION)
                message = check_message_pack(self.protocol.read())

        return check_message_protocol(
            message, COMMAND_FIRMWARE_VERSION).split(b"\\x00")[0].decode()'''

changed = []
for name, before, after in (("read_otp length", otp_before, otp_after),
                            ("firmware_version ack", fw_before, fw_after)):
    if after in src:
        print(f"  already applied: {name}")
        continue
    if src.count(before) != 1:
        sys.exit(f"error: cannot apply '{name}' -- expected exactly one match, "
                 f"found {src.count(before)}. goodix.py has changed upstream; "
                 f"re-check the fix by hand rather than forcing it.")
    src = src.replace(before, after)
    changed.append(name)

if changed:
    path.write_text(src)
    for name in changed:
        print(f"  applied: {name}")
PY

if [[ ! -d .venv ]]; then
  echo "creating virtualenv"
  python3 -m venv .venv || die "venv creation failed"
fi
# protocol.py imports the SPI backends at module scope even though this sensor is USB, so
# the whole requirements set has to be present just to import the driver.
./.venv/bin/pip install --quiet --upgrade pip >/dev/null 2>&1
./.venv/bin/pip install --quiet -r requirements.txt || die "dependency install failed"
./.venv/bin/python -c "import driver_52xd" \
  || die "the tool still does not import; fix that before going near the sensor"
echo "dependencies installed and the driver imports cleanly"

cat <<EOF

Ready. Nothing has touched the sensor.

Read-only probe first -- firmware, key digest and calibration data, no writes:
  cd $DEST
  sudo ./.venv/bin/python -c 'import driver_52xd, goodix, protocol; \\
d = driver_52xd.init_device(0x521d); \\
print("firmware:", d.firmware_version()); \\
print("key digest:", d.preset_psk_read(0xbb020001, 32, 0)[2].hex()); \\
print("otp:", d.read_otp().hex())'

The re-keying run itself, which is the irreversible step, is:
  cd $DEST && sudo ./.venv/bin/python run_521d.py
Run it from $DEST, never via 'sudo -i', or the relative firmware path will not resolve.
Success is the printed lines "Firmware: GFUSB_GM168SEC_APP_10019" and "Valid PSK: True",
not a clean exit code.
EOF
