# Goodix 27c6:521d fingerprint reader — Observations

**Status:** blocked at driver activation. Enrollment has never succeeded.
**Date of last measurement:** 2026-09-07
**Branch:** `worktree-fingerprint-auth` (worktree of `SMS-Supercharge-My-Shell`)

This file records **only what was measured or read directly from source**. Interpretation,
theories and proposed fixes live in `hypothesis.md`. Anything not verified is marked
explicitly as unverified.

---

## 1. Goal

Biometric authentication on an ASUS ROG Zephyrus G15 (GA503QS) for two consumers:

1. the Noctalia lock screen, and
2. 1Password.

Face unlock was ruled out before this log begins: the machine has no IR camera, the
external Insta360 has no IR, and Howdy is abandoned. Fingerprint is the remaining option.

---

## 2. Hardware and platform

| Item | Value |
|---|---|
| Machine | ASUS ROG Zephyrus G15 GA503QS |
| OS | CachyOS (Arch-based), kernel `7.2.2-1-cachyos` |
| Compositor / shell | niri + Noctalia `v5.0.1` (`5.0.1-1-dirty`) |
| Display manager | sddm |
| Shell | fish |
| Bootloader | Limine (`Boot0008`) |
| Fingerprint reader | Goodix `27c6:521d`, USB descriptor strings `Goodix` / `FingerPrint` |
| Reader sysfs path | `/sys/bus/usb/devices/3-3` |
| Reader bus/dev | bus 3, device 2 → `/dev/bus/usb/003/002` |
| Reader `bcdDevice` | `0100`; no USB serial number exposed |

**Dual boot confirmed.** `efibootmgr` lists `Boot0003* Windows Boot Manager`
(`\EFI\MICROSOFT\BOOT\BOOTMGFW.EFI`). `lsblk` shows two NTFS partitions:

- `nvme0n1p2` — 952.7 G (Windows system volume)
- `nvme0n1p4` — 642 M (recovery)

Neither is mounted.

**Session context** (relevant to polkit):

```
loginctl session-status
  2 - a_merii (1000)   State: active   Seat: seat0; vc1   TTY: tty1
  Service: sddm   Type: wayland   Class: user   Desktop: niri
```

---

## 3. Software state

| Package | Version |
|---|---|
| `libfprint-goodixtls52xd` (ours) | `1.94.10.r2013.g72cacc3-1` |
| `fprintd` | `1.94.5-2.1` |
| stock `libfprint` | **removed** (conflicts with ours) |

The vendored driver package **replaces** Arch's `libfprint`. It `provides=(libfprint …
libfprint-2.so)` and `conflicts=(libfprint …)`.

> Earlier false negative worth knowing about: on the first attempt, paru satisfied
> `fprintd`'s `libfprint` dependency from the **repo** rather than from the AUR package, so
> stock `libfprint` got installed and `fprintd-list` reported `No devices available`. Stock
> libfprint contains no `521d` support. The fork must be installed *alone*, accepting the
> conflict prompt.

### Repository changes already merged

PR **#45**, squash-merged as **`c2b614a`** on `origin/main`:

- `packages/libfprint-goodixtls52xd/PKGBUILD` — vendored, pins
  `#commit=72cacc37ca6524390a112e7df7bf2c6972be8217` from
  `github.com/AH-Merii/libfprint` (our fork of `djnz00/libfprint`).
- `packages/libfprint-goodixtls52xd/guard` — hardware guard; exits non-zero (skip) unless
  USB `27c6:521d` is attached, via sysfs rather than `lsusb`.
- `packages/.gitignore` — makepkg artefacts.
- `mise-tasks/localpkgs` — builds `packages/*/PKGBUILD`, gated on `profile == desktop`
  **and** `pacman` being present. Deliberately **not** part of `mise run setup`.
- `lib/plan.sh` — added `local_pkg_state()` and `plan_local_packages()`.
- `pkglist/arch-desktop.txt` — added `fprintd`.
- `README.md` — registry sections updated.

**The fork `AH-Merii/libfprint` carries no code changes.** It exists so the pinned commit
cannot vanish. The AUR package it replaces tracked `#branch=master`; the clone HEAD was
`72cacc3`, three commits ahead of the AUR-advertised `39e145b`, confirming the moving-target
risk was real.

### Build note

A full `makepkg` check phase fails on `libfprint:metainfo-validate` — `appstreamcli`
performing a *network* reachability check against an unreachable freedesktop URL. 127/128
tests pass. Our PKGBUILD's `check()` therefore runs only `goodixtls52xd-frame` and
`goodixtls-protocol`.

---

## 4. What works

Device detection is fully functional. This is already further than every one of the 505
`linux-hardware.org` probes for this device, which all failed at detection.

```
$ fprintd-list $USER
found 1 devices
Device at /net/reactivated/Fprint/Device/0
User a_merii has no fingers enrolled for Goodix TLS Fingerprint Sensor 52XD.
```

From the instrumented run, probe and open both complete cleanly:

```
Selected device 0 (Goodix TLS Fingerprint Sensor 52XD) claimed by goodixtls52xd driver
libfprint-image_device: Image device open completed
libfprint-device: Device reported open completion
Opened device.
The device supports fingerprint updates.
```

---

## 5. Failure 1 — polkit denies unprivileged enroll

```
$ fprintd-enroll -f right-index-finger
EnrollStart failed: GDBus.Error:net.reactivated.Fprint.Error.PermissionDenied:
  Not Authorized: net.reactivated.fprint.device.enroll
```

Journal:

```
fprintd[1309660]: Authorization denied to :1.1644 to call method 'EnrollStart'
  for device 'Goodix TLS Fingerprint Sensor 52XD':
  Not Authorized: net.reactivated.fprint.device.enroll
```

The policy permits it for an active session:

```
$ pkaction --action-id net.reactivated.fprint.device.enroll --verbose
net.reactivated.fprint.device.enroll:
  implicit any:      no
  implicit inactive: no
  implicit active:   auth_self_keep
```

The session **is** `active` on `seat0`, so an authentication agent should have prompted.
No prompt appeared. **Unresolved.** Not currently blocking, because running as root gets
past it and reaches Failure 2.

---

## 6. Failure 2 — activation aborts on PSK hash mismatch (the real blocker)

```
$ sudo fprintd-enroll -f right-index-finger a_merii
Enroll result: enroll-unknown-error
```

Journal:

```
fprintd[1310923]: MCU has no config          (x3)
fprintd[1310923]: failed during activation: Unsupported device PSK hash (code: 35)
fprintd[1310923]: Device reported an error during identify for enroll:
                  Unsupported device PSK hash
```

### Instrumented measurement

To obtain the values the driver refuses to print, a **scratch-only** patch adding
`fp_warn()` calls was applied to `goodix52xd.c` **in paru's cache**
(`~/.cache/paru/clone/libfprint-goodixtls52xd-git/src/libfprint/`), rebuilt incrementally
with `ninja`, and exercised via libfprint's own `examples/enroll`, which has an rpath into
the build directory. **Nothing was installed; `/usr/lib` was untouched.**

Results:

```
SMSDIAG firmware="GFUSB_GM168SEC_APP_10019"
SMSDIAG flags=0xbb020001 len=32
SMSDIAG device_hash=163ec2b1470b66fc7c2ec87822f9a82a1b4b17ce867f3c1784400c58461907bb
SMSDIAG driver_hash=66687aadf862bd776c8fc18b8e9f8e20089714856ee233b3902a591d0d5f2925

[goodixtls52xd] SSM ACTIVATE_NUM_STATES failed in state 4
  with error: Unsupported device PSK hash
failed during activation: Unsupported device PSK hash (code: 35)
```

State 4 is `ACTIVATE_CHECK_PSK`. The preceding states — including `ACTIVATE_CHECK_FW_VER`
— all pass. `MCU has no config` is emitted three times, in states 1, 3 and 4, **before**
the PSK failure.

**The four facts that matter:**

1. Firmware is **`GFUSB_GM168SEC_APP_10019`** — the *older* of the two supported strings.
   The fork's README names `GFUSB_GM168SEC_APP_10034` as "the active production target".
2. The device's stored hash is `163ec2b1…`.
3. The driver expected `66687aad…`.
4. Flags (`0xbb020001`) and length (32) both match; **only the hash content differs.**

---

## 7. Verified cryptographic facts

Computed locally and confirmed:

| Claim | Result |
|---|---|
| `sha256(32 zero bytes)` == `goodix_52xd_pmk_hash_10019` | **true** |
| `sha256(goodix_52xd_psk_10034)` == `goodix_52xd_pmk_hash_10034` | **true** |
| `device_hash` == `sha256(32 zero bytes)` | false |
| `device_hash` == `sha256(goodix_52xd_psk_10034)` | false |

So:

- The stored value is **plain `sha256(PSK)`** — no salt, no KDF.
- The 10019 PSK is the well-known **32 zero bytes** constant
  (`66687aad…` is a widely-recognised hash).
- The 10034 PSK is the baked-in constant
  `85c198da3a7240e2221f5d5afa4b434356c745bb77b5391392e95d0f4a39a427`.

A search over **267 candidate PSKs** (all-zeros, all-`0xff`, every `bytes([b])*32` for
b in 0..255, `bytes(range(32))`, ASCII fillers, `sha256` of several strings, and the 10034
constant) produced **no match** for `163ec2b1…`.

**Consequence: the sensor's PSK cannot be recovered from its hash.** SHA-256 is one-way and
the value is not a known constant. It can only be *replaced*, or *obtained from elsewhere*.

Script: `$CLAUDE_JOB_DIR/tmp/psk-search.py`.

---

## 8. Source-code facts

All line numbers are at pinned commit `72cacc3`, under
`libfprint/drivers/goodixtls/`.

### `goodix52xd.h`

| Line | Content |
|---|---|
| 27 | `#define GOODIX_52XD_FIRMWARE_VERSION ("GFUSB_GM168SEC_APP_10019")` |
| 28 | `#define GOODIX_52XD_FIRMWARE_VERSION_10034 ("GFUSB_GM168SEC_APP_10034")` |
| 30 | `#define GOODIX_52XD_PSK_FLAGS (0xbb020001)` |
| 34 | `goodix_52xd_pmk_hash_10019[]` |
| 39 | `goodix_52xd_pmk_hash_10034[]` |
| 44 | `goodix_52xd_psk_10034[]` — the actual 10034 PSK |
| 76 | `{.vid = 0x27c6, .pid = 0x521d},` — proves this device is targeted |

### `goodix52xd.c`

| Line | Content |
|---|---|
| 163–172 | `ACTIVATE_*` enum. Order: `READ_AND_NOP`, `ENABLE_CHIP`, `NOP`, `CHECK_FW_VER`, **`CHECK_PSK` (state 4)**, `RESET`, `OTP`, `SET_MCU_IDLE`, `SET_MCU_CONFIG` |
| 184–189 | `goodix52xd_firmware_supported()` — accepts 10019 **or** 10034 |
| 191–211 | `goodix52xd_set_expected_pmk_hash()` — maps firmware string → expected hash; sets `firmware_10034` flag |
| 214–230 | `goodix52xd_get_tls_psk()` — **returns `NULL` unless `firmware_10034`** |
| 232–250 | `check_firmware_version()` |
| 279–330 | `check_preset_psk_read()` — validates flags, then length, then `memcmp` |
| 314 | the `memcmp`; its error string `"Unsupported device PSK hash"` is on line 316 |
| 366–384 | `goodix52xd_send_upload_config()` — patches 3 bytes for 10034 only |
| 413–416 | `ACTIVATE_CHECK_PSK` → `goodix_send_preset_psk_read(dev, GOODIX_52XD_PSK_FLAGS, 32, …)` |
| 449–462 | `activate_complete()` — **calls `goodix_tls()` only when `error == NULL`** |

### `goodix.c`

| Line | Content |
|---|---|
| 215 | `goodix_receive_preset_psk_read()` |
| 270 | `goodix_receive_preset_psk_write()` |
| 337 | `if (ack->has_no_config) fp_warn("MCU has no config");` |
| 1196 | `goodix_send_preset_psk_write()` — **fully implemented, zero callers anywhere in the tree** |
| 1229 | `goodix_send_preset_psk_read()` |
| 1575 | `goodix_tls_set_psk_from_hex()` |
| 1623 | `goodix_tls()` — reads `g_getenv("LIBFPRINT_GOODIXTLS_PSK_HEX")` at line 1632 |

### Two structural conclusions from the code

1. **`LIBFPRINT_GOODIXTLS_PSK_HEX` is never read on this path.** It is read inside
   `goodix_tls()`, which `activate_complete()` invokes **only after the activation SSM
   succeeds**. The failure occurs *inside* the SSM at state 4. Setting the variable today
   changes nothing. (Verified by reading the call graph, not by experiment.)

2. **The driver cannot provision a PSK.** `goodix_send_preset_psk_write()` exists in the
   protocol layer but no driver calls it. `ACTIVATE_CHECK_PSK` only ever *reads* and then
   hard-fails.

Additionally: for firmware 10019, `goodix52xd_get_tls_psk()` returns `NULL`. Even if the
hash check passed, the TLS handshake would have no PSK unless supplied via the environment
override. The 10019 path is only usable *with* that variable.

### Wire format

`goodix_send_preset_psk_read` response payload:

```
[status:1][flags:4 LE][length:4 LE][psk_hash:32]
```

Searchable signature on the wire: `01 00 02 bb  20 00 00 00` followed by the 32-byte hash.
(Derived from source; a USB capture was prepared but never needed.)

---

## 9. Noctalia integration facts

From binary inspection of `/usr/bin/noctalia` v5.0.1:

- Settings schema contains `settings.schema.lockscreen.fingerprint.label` /
  `.description` → TOML key `[lockscreen] fingerprint`.
- fprintd D-Bus methods referenced: **`Claim`, `Release`, `VerifyStart`, `VerifyStop`
  only**. **Zero** occurrences of "enroll".
  → **Noctalia is verify-only. It cannot enroll or delete fingerprints.** Enrollment must
  happen elsewhere (`fprintd-enroll`, or our own task).
- `src/auth/pam_authenticator.cpp:184` — PAM service defaults to `"login"`.

Noctalia has no systemd unit; it is spawned by niri
(`desktop/niri/.config/niri/cfg/autostart.kdl:4`). Restart with:

```
pkill -x noctalia; niri msg action spawn -- noctalia
```

To check whether a restart actually took effect, use
`readlink /proc/$(pgrep -x noctalia)/exe` — a `(deleted)` suffix means the old inode is
still running. `noctalia --version` reads the **on-disk** binary and will mislead you.

---

## 10. Security review of the driver (clean)

Read at pinned commit `72cacc3`:

- No `system`, `popen`, `exec*`, `socket`, `connect`, or `curl`.
- The only file writes are debug frame dumps, gated behind **two** environment variables
  (`GOODIX52XD_DUMP_DIR` **and** `GOODIX52XD_DUMP_RAW=1`), created `0700`, with an explicit
  `refusing to dump Goodix 52xd frames into non-private directory` guard.

---

## 11. Artefacts produced

Scratch (job temp dir, `/home/a_merii/.config/claude/jobs/aa87c10b/tmp/`):

| File | Purpose |
|---|---|
| `psk-diag.sh` | Stops fprintd, runs patched `examples/enroll`, prints `SMSDIAG` lines. Output tee'd live. |
| `psk-diag.log` | Full debug log of the successful diagnostic run. |
| `psk-search.py` | 267-candidate PSK search. Result: no match. |
| `find-psk.sh` | **Not yet run.** Read-only scan of the Windows partition for the PSK. |

Scratch patch, applied **only** in
`~/.cache/paru/clone/libfprint-goodixtls52xd-git/src/libfprint/libfprint/drivers/goodixtls/goodix52xd.c`:

- `fp_warn("SMSDIAG firmware=…")` in `check_firmware_version()`
- a hex-dump block printing `flags`, `device_hash`, `driver_hash` before the `memcmp` in
  `check_preset_psk_read()`

> **This patch must never reach the fork.** It is diagnostic scaffolding. Per the user's
> standing instruction, any *real* driver change must be committed to
> `AH-Merii/libfprint` first, then `packages/libfprint-goodixtls52xd/PKGBUILD` gets its
> `source=` commit, `pkgver` and header comment bumped together — the reviewed-bump path
> the PKGBUILD header describes.

---

## 12. Open items

1. **Blocker:** PSK hash mismatch (§6). Nothing else can proceed until this is resolved.
2. `find-psk.sh` has not been run.
3. polkit `PermissionDenied` on unprivileged enroll (§5) — unresolved, not blocking.
4. `mise-tasks/fingerprint` — designed in principle, not built. Intended shape: extract
   `usb_device_present <vid> <pid>` into `lib/` (reused by the `guard` script); derive an
   idempotent state machine from live `fprintd-list` output rather than marker files;
   verify with 3× `fprintd-verify` after enrolling; add a conditional reminder to the
   "things that still need you" trailer in `mise-tasks/setup` (lines 55–63), alongside the
   existing `chsh` and `ggh` entries. Explicitly **not** to write `settings.toml`.
   Note `mise-tasks/setup` refuses to run from a worktree (lines 17–20).
5. `[lockscreen] fingerprint = true` in
   `desktop/noctalia/.local/state/noctalia/settings.toml` — deferred until enrollment and
   verification actually work.
6. `pam_fprintd.so` in `/etc/pam.d/polkit-1` for 1Password — a separate, deferred decision.
   CVE-2024-37408 (fprintd has no security attention mechanism) applies to the polkit path,
   though **not** to the D-Bus lock-screen path. Covers 1Password's `unlock`,
   `authorizeCLI` and `authorizeSshAgent`. Keep `pam_fprintd` **out** of `/etc/pam.d/sudo`
   — the installed `shelly 3.1.2` warns about exactly this.

---

## 13. Reproducing the diagnostic

```sh
# fprintd holds the device exclusively
sudo systemctl stop fprintd

# patched build, rpath'd to the build dir -- installs nothing
printf '6\n' | G_MESSAGES_DEBUG=all \
  ~/.cache/paru/clone/libfprint-goodixtls52xd-git/src/build/examples/enroll
```

`examples/enroll` is interactive: `finger_chooser()` (`utilities.c:111`) reads stdin before
the device is opened, hence the piped `6`. `discover_device()` (`utilities.c:29`) only
prompts when more than one device is present, which is not the case here.
