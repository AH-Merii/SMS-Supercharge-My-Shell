# Goodix 27c6:521d — Runbook

The ordered procedure. Read `observations.md` for the facts and `hypothesis.md` for why the
order is this way.

Every step below needs root, which is why none of them have been run yet.

**The ordering principle: everything reversible happens before anything irreversible, and
each irreversible step is preceded by the check that could make it unnecessary.**

---

## Step 1 — Ask Windows for the key. Read-only.

The one route that preserves Windows Hello, and the last moment it can be attempted. Once
step 4 runs, this question is unanswerable forever.

```sh
sudo docs/fingerprint/tools/collect-windows-psk-evidence.sh
python3 docs/fingerprint/tools/check-psk-candidates.py ~/goodix-psk-evidence
```

The first mounts the Windows volume read-only, copies out the vendor's data directory, the
registry hives, the machine-scope protection state and the vendor driver, then unmounts. The
second decides, offline, whether any of it contains this sensor's key.

- **Key found** → skip to step 6. Nothing gets overwritten and both systems keep working.
- **No key** → continue. Expect this; see `hypothesis.md` §3 for why.

Either way you now have the vendor driver copied out, which is the only source of the newer
firmware image.

---

## Step 2 — Prepare the tool. Touches no hardware.

```sh
docs/fingerprint/tools/prepare-goodix-tool.sh
```

Clones the community tool, **proves the recovery firmware is present and correct before
anything can erase the sensor**, applies the two fixes it needs, and builds a virtualenv.
Idempotent.

This ordering is the point. The tool erases the sensor one loop iteration *before* it opens
the replacement image, and opens it by a relative path. A wrong working directory is the
documented cause of the only "stuck in the bootloader" report there is.

---

## Step 3 — Probe the sensor. Read-only.

```sh
cd ~/src/goodix-fp-dump
sudo ./.venv/bin/python -c 'import driver_52xd; \
d = driver_52xd.init_device(0x521d); \
print("firmware:", d.firmware_version()); \
print("key digest:", d.preset_psk_read(0xbb020001, 32, 0)[2].hex()); \
print("otp:", d.read_otp().hex())'
```

Three plaintext reads, no writes. This confirms, at zero cost:

- that the tool can talk to the sensor at all, and that the acknowledgement fix works;
- that the digest still matches what the driver reported, so nothing has changed underneath;
- this unit's calibration bytes, which the driver's 10019 path hardcodes. If they differ
  markedly from the values in the reference implementation's comments, expect capture
  problems later and say so before spending step 4.

Record the output. If this step fails, **do not proceed to step 4** — the failure is
diagnostic and costs nothing to investigate.

---

## Step 4 — Re-key the sensor. **Irreversible. Needs an explicit decision.**

Do not run this without having read `hypothesis.md` §6 and §8. In short: Windows Hello stops
working, it will need redoing every time Windows re-provisions the sensor, and the published
accuracy results for this sensor are poor.

```sh
sudo systemctl stop fprintd
cd ~/src/goodix-fp-dump && sudo ./.venv/bin/python run_521d.py
```

Run it from that directory. Never via `sudo -i`, which changes the working directory and
breaks the relative firmware path.

**Success is the printed pair of lines**

```
Firmware: GFUSB_GM168SEC_APP_10019
Valid PSK: True
```

**not** a clean exit. The run is expected to end in a traceback after that point; the tool's
own demonstration code runs on past the part we need.

If it fails partway: this is recoverable. Reset the USB device and run it again — the tool's
loop re-enters the bootloader and reflashes. A traceback is not a brick.

```sh
sudo ./usbreset /dev/bus/usb/003/002   # rebuild from goodix-fp-dump's usbreset if needed
```

---

## Step 5 — First real test, against the driver already installed.

Deliberately *before* installing the rebuilt package, so that if something fails you know it
is the sensor and not the new code.

```sh
sudo systemctl stop fprintd
printf '6\n' | G_MESSAGES_DEBUG=all \
  LIBFPRINT_GOODIXTLS_PSK_HEX=0000000000000000000000000000000000000000000000000000000000000000 \
  ~/.cache/paru/clone/libfprint-goodixtls52xd-git/src/build/examples/enroll
```

The installed build passes the gate on its own once the sensor holds the all-zero key, and
takes the key from that variable. What matters is **how far it gets**:

- past `ACTIVATE_CHECK_PSK` → the key problem is solved;
- then blank or garbage frames → `hypothesis.md` §7, suspects 2 and 3;
- then a working capture → go to step 6.

Collect frames while doing it:

```sh
GOODIX52XD_DUMP_DIR=~/goodix-frames GOODIX52XD_DUMP_RAW=1   # plus the above
```

---

## Step 6 — Install the rebuilt driver.

```sh
sudo pacman -U packages/libfprint-goodixtls52xd/libfprint-goodixtls52xd-1.94.10.r2014.gff4f8c0-1-x86_64.pkg.tar.zst
```

This removes the need for the environment variable on the all-zero key, and is what lets a
*recovered* key work if step 1 succeeded.

If you are using a recovered key rather than the all-zero one, install it properly rather
than exporting it in a shell — `fprintd` is D-Bus activated and inherits nothing:

```sh
sudo systemctl edit fprintd.service
# [Service]
# Environment=LIBFPRINT_GOODIXTLS_PSK_HEX=<key>
```

Better still, keep the key in a root-owned `0600` file and use `EnvironmentFile=`. Do not
commit it; this repository is public.

---

## Step 7 — Enrol, then measure honestly.

Restart niri first so the polkit agent from commit `80fc359` is running, otherwise
`fprintd-enroll` is denied with no prompt.

```sh
fprintd-enroll -f right-index-finger
```

Then apply the criterion from `hypothesis.md` §8 before wiring anything up:

- an enrolled finger must verify **at least 8 times in 10**;
- **two other fingers** must produce **zero** acceptances across 10 attempts each.

```sh
for i in $(seq 10); do fprintd-verify -f right-index-finger; done
```

If it fails the criterion, stop. Do not lower the threshold.

---

## Step 8 — Only then, wire it up.

1. `mise-tasks/fingerprint`, idempotent, deriving state from live `fprintd-list` output
   rather than marker files. Note `mise-tasks/setup` refuses to run from a worktree.
2. `[lockscreen] fingerprint = true` in Noctalia's settings. Noctalia is verify-only — it
   cannot enrol, and never needed the polkit fix, since verify is permitted for an active
   session.
3. 1Password and `pam_fprintd` remain a **separate** decision. Keep `pam_fprintd` out of
   `/etc/pam.d/sudo`.

---

## If Windows re-keys the sensor later

Expect this after any Windows Hello enrolment. Recovery is steps 4 and 5 again; nothing else
changes. The recovery firmware lives at `~/.local/share/goodix-firmware/`, and
`prepare-goodix-tool.sh` restores it into the checkout automatically if the upstream
repository has disappeared.
