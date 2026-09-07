# Goodix 27c6:521d fingerprint reader — Observations

**Status:** blocked at driver activation. The sensor holds a key no host here knows.
The blocker is now understood and has a known remedy; the remedy is irreversible.
**Date of last measurement:** 2026-09-07
**Branch:** `worktree-fingerprint-auth`

This file records **only what was measured, read from source, or verified against a primary
document**. Interpretation, routes and risk live in `hypothesis.md`; the ordered procedure
lives in `runbook.md`. Anything unverified is marked as such.

---

## 0. Resume here

Nothing has touched the sensor or the Windows partition. Every remaining step needs root,
which is why they have not been run.

### What changed on this branch

| Commit | Change | Verified |
|---|---|---|
| `ff4f8c0` (libfprint fork) | 52xd driver supplies the 10019 key; env key can satisfy the gate; mismatch error names both digests | tests pass, **not** against hardware |
| `eb3546c` | PKGBUILD pinned to `ff4f8c0`, `1.94.10.r2014.gff4f8c0` | builds clean |
| `80fc359` | polkit authentication agent added to package list and niri autostart | agent's absence confirmed, prompt **not** confirmed |
| `ef74db1` | these docs rewritten, `tools/` added | tools tested against synthetic and real inputs |
| `b25b51d` | `docs/` added to the README layout map | trivial |

The driver commit lives on branch `goodixtls52xd-10019-psk` of `AH-Merii/libfprint`, pushed.

### What is and is not live

- The rebuilt package is **built but not installed**. `r2013` is still the installed one.
- The polkit fix is **committed but not applied**; it needs a niri restart.
- The recovery firmware is saved at `~/.local/share/goodix-firmware/`, outside both the repo
  and the disposable job directory. **Do not lose it**; an erase without it is unrecoverable.

### The one thing blocking everything else

Making this sensor work means overwriting the key Windows wrote to it, which means erasing
and reflashing its firmware. That is irreversible and it breaks Windows Hello, repeatedly.
See `hypothesis.md` §10 for the decision as it stands, and §8 for the accuracy criterion
agreed before any of it runs.

### First command when picking this back up

The read-only search that would make the irreversible step unnecessary. Poor odds, no risk,
and the last moment it can be asked.

```sh
sudo docs/fingerprint/tools/collect-windows-psk-evidence.sh
python3 docs/fingerprint/tools/check-psk-candidates.py ~/goodix-psk-evidence
```

---

## 1. Goal

Biometric authentication on an ASUS ROG Zephyrus G15 (GA503QS) for two consumers:

1. the Noctalia lock screen, and
2. 1Password.

Face unlock was ruled out before this log begins: no IR camera, the external Insta360 has no
IR, Howdy abandoned. Fingerprint is the remaining option.

---

## 2. Hardware and platform

| Item | Value |
|---|---|
| Machine | ASUS ROG Zephyrus G15 GA503QS |
| OS | CachyOS (Arch-based), kernel `7.2.2-1-cachyos` |
| Compositor / shell | niri + Noctalia `v5.0.1` |
| Display manager | sddm |
| Fingerprint reader | Goodix `27c6:521d`, USB strings `Goodix` / `FingerPrint` |
| Reader sysfs path | `/sys/bus/usb/devices/3-3` |
| Reader device node | `/dev/bus/usb/003/002`, `crw-rw-r-- root root` |

The device node is **not** user-accessible. There is no `uaccess` tag and the user is not in a
group with write access, so every hardware operation below needs root.

**Dual boot confirmed.** `nvme0n1p2` is 952.7 G, `fstype ntfs` — **not** BitLocker, so a
read-only mount needs no recovery key. `nvme0n1p4` is the 642 M recovery volume. Neither is
mounted.

---

## 3. Software state

| Package | Version |
|---|---|
| `libfprint-goodixtls52xd` (ours) | `1.94.10.r2013.g72cacc3-1` **installed** |
| `libfprint-goodixtls52xd` (ours) | `1.94.10.r2014.gff4f8c0-1` **built, not installed** |
| `fprintd` | `1.94.5-2.1` |
| stock `libfprint` | removed (conflicts with ours) |

> Earlier false negative worth knowing about: paru will satisfy `fprintd`'s `libfprint`
> dependency from the **repo** rather than the AUR package, installing stock `libfprint`,
> which has no `521d` support, and `fprintd-list` then reports `No devices available`.

---

## 4. What works

Device detection is fully functional — already further than every one of the 505
`linux-hardware.org` probes for this device, which all failed at detection.

```
$ fprintd-list $USER
found 1 devices
Device at /net/reactivated/Fprint/Device/0
User a_merii has no fingers enrolled for Goodix TLS Fingerprint Sensor 52XD.
```

Probe and open both complete cleanly. Activation is where it stops.

---

## 5. Failure 1 — polkit denied unprivileged enroll. **Cause found.**

```
$ fprintd-enroll -f right-index-finger
EnrollStart failed: GDBus.Error:net.reactivated.Fprint.Error.PermissionDenied:
  Not Authorized: net.reactivated.fprint.device.enroll
```

The policy allows it (`implicit active: auth_self_keep`) and the session **is** active on
`seat0`, yet no prompt appeared.

**Measured cause: there is no polkit authentication agent in this session.**

- `busctl --user list` matches nothing for polkit; the only polkit name on the system bus is
  `org.freedesktop.PolicyKit1`, owned by `polkitd` itself.
- The only polkit-related package installed is `polkit`. No agent package is present.
- `desktop/niri/.config/niri/cfg/autostart.kdl` spawned only `noctalia`.

So `polkitd` had nobody to ask, and every `auth_self` or `auth_admin` action was refused
silently. This is **not fingerprint-specific**; it affected every privileged operation in the
session.

**Fixed** in commit `80fc359`: `mate-polkit` added to `pkglist/arch-desktop.txt` and its
agent spawned from `autostart.kdl`. The binary path
`/usr/lib/mate-polkit/polkit-mate-authentication-agent-1` was verified against the package's
actual file list, not assumed. **The prompt itself is unverified** — that needs a niri
restart.

Note `net.reactivated.fprint.device.verify` is `implicit active: yes`, so the Noctalia lock
screen was never going to be blocked by polkit. Only enroll was.

---

## 6. Failure 2 — activation aborts on PSK hash mismatch. **The real blocker.**

```
fprintd[1310923]: MCU has no config          (x3)
fprintd[1310923]: failed during activation: Unsupported device PSK hash (code: 35)
```

### Instrumented measurement

A scratch-only `fp_warn()` patch in paru's build cache, exercised through libfprint's own
`examples/enroll` (which has an rpath into the build directory, so nothing was installed):

```
SMSDIAG firmware="GFUSB_GM168SEC_APP_10019"
SMSDIAG flags=0xbb020001 len=32
SMSDIAG device_hash=163ec2b1470b66fc7c2ec87822f9a82a1b4b17ce867f3c1784400c58461907bb
SMSDIAG driver_hash=66687aadf862bd776c8fc18b8e9f8e20089714856ee233b3902a591d0d5f2925
[goodixtls52xd] SSM ACTIVATE_NUM_STATES failed in state 4
```

State 4 is `ACTIVATE_CHECK_PSK`. Everything before it passes. Flags and length match; only
the digest differs. `MCU has no config` appears three times *before* the failure, and config
upload is state 8, so it is a symptom of stopping early, not a second fault.

The driver no longer requires this patch to reveal these values — see §9.

---

## 7. Verified cryptographic facts

Computed locally (`docs/fingerprint/tools/`, and the driver's own unit tests):

| Claim | Result |
|---|---|
| `sha256(32 zero bytes)` == `goodix_52xd_pmk_hash_10019` | **true** |
| `sha256(goodix_52xd_psk_10034)` == `goodix_52xd_pmk_hash_10034` | **true** |
| `device_hash` == `sha256(32 zero bytes)` | false |
| `device_hash` == `sha256(goodix_52xd_psk_10034)` | false |
| `device_hash` == `sha256` of the white-box blob, or of any 32-byte window of it | false |
| `device_hash` == `sha256(pmk_wrap(k))` for any of the above `k` | false |

So the stored value is **plain `sha256(PSK)`** for this sensor family — no salt, no key
derivation — and this unit's key is none of the keys obtainable anywhere.

**Consequence: this sensor's key cannot be recovered from its digest.** It can be supplied
from elsewhere, or replaced.

Note the derivation is *not* uniform across the family. The 51x7/5125 drivers report
`sha256(white-box blob)` while 52xd reports `sha256(plaintext key)`. A candidate key for this
unit can therefore be checked offline with a plain `sha256`.

---

## 8. The re-keying mechanism, and where the key came from

This is the material correction to the earlier version of this document, which concluded the
situation was near-hopeless. It is not.

### Where the key came from

The Goodix Windows driver implements trust-on-first-use. Its own debug symbols and a
published reverse-engineering trace show `PresetPskWriteKey` doing: *generate random psk →
encrypt psk by white box → write to mcu*. On a host that cannot decrypt its stored copy, it
generates a **fresh random key** and writes it. That is the most economical explanation for a
unit running the stock community firmware while holding a digest matching nothing.

### The community tool re-keys sensors routinely

`goodix-fp-dump`'s `driver_52xd.py` is written for exactly this device and exactly this
situation. Its `main()` is a state machine:

- firmware is the 10019 target and the key is wrong → `mcu_erase_app`, dropping to the IAP
  bootloader;
- firmware is IAP and the key is wrong → `preset_psk_write(0xbb010003, white_box, …)`, then
  reflash 10019 and reset;
- firmware is the target and the key is right → run.

The 96-byte white-box blob is a fixed constant, identical across the 52xd, 53xd and 53x5
drivers, that encodes the **all-zero key**. After writing it the sensor reports `66687aad…`
— exactly what our driver expects for 10019.

### The recovery firmware exists and is held locally

Without it, an erase would be unrecoverable. It was fetched from four independent paths
(standalone clone, submodule checkout, a commit-pinned raw fetch, and the repository's only
fork) which agree byte for byte.

| Item | Value |
|---|---|
| File | `GFUSB_GM168SEC_APP_10019.bin` |
| Size | 25200 bytes |
| sha256 | `6ff41957f387160c089559dffff6e8a26d1fa344d01bdaa6d62c5dab61883804` |
| Kept at | `~/.local/share/goodix-firmware/` |

Kept outside the repository deliberately: the upstream README states the images are Goodix
property and must not be copied into other repositories. Kept outside the job directory
because that is deleted with the job, and the source repository has had no push since
2023-05-30 and has one fork.

**No 10034 image exists publicly.** Its only known source is `wbdi.dll` inside the Windows
driver store on this machine's own Windows partition.

### Two defects in the tool that must be fixed before running it

Both verified by reading the source; the fixes are applied by
`docs/fingerprint/tools/prepare-goodix-tool.sh` and confirmed working.

1. `read_otp()` sends `b"\x00\x00"`. The first payload byte is the **requested length**, so
   it asks for zero bytes, gets nothing, and raises `Invalid OTP` — *after* the erase, key
   write and reflash have all succeeded. Every documented run hits this. The historical
   workaround of faking the OTP is reported by two users to produce a reader that matches the
   wrong finger; do not use it. Our C driver already requests `0x40` and does not have this
   bug.
2. `firmware_version()` assumes the sensor acknowledges before answering. A sensor
   provisioned by another operating system answers without the acknowledgement, so the tool
   dies on its **first call**, before the erase. The same sensor acknowledges normally again
   once re-keyed, so the fix must accept both shapes. Ours dispatches on the command byte.

---

## 9. Driver work completed

Commit `ff4f8c0` on branch `goodixtls52xd-10019-psk` of `AH-Merii/libfprint`, pinned by
`packages/libfprint-goodixtls52xd/PKGBUILD` at `1.94.10.r2014.gff4f8c0` (commit `eb3546c`).

Three changes, all in the 52xd path:

1. **`goodix52xd_get_tls_psk()` returned `NULL` for 10019.** A sensor on that firmware
   therefore reached the TLS handshake with no key at all, and `goodix_tls_server_init()`
   fails closed on a null key. That branch could never have worked. It now returns the
   all-zero key, which is provably the one matching the digest the driver already expects.
2. **`LIBFPRINT_GOODIXTLS_PSK_HEX` can now satisfy the activation check**, when `sha256` of
   the supplied key equals what the device reports. Previously the variable was read only
   inside `goodix_tls()`, which runs *after* the activation state machine succeeds, so it
   could never help with this gate. This is what makes a recovered key usable.
3. **The mismatch error reports both digests.** Previously it named neither.

The gate stays fail-closed in both directions. A handshake is still only attempted with a key
the device has confirmed by digest that it holds, and a set-but-wrong override now fails at
the gate rather than reaching OpenSSL.

Verified: full `meson test` suite passes except `metainfo-validate`, the network lint the
PKGBUILD already skips. Five new unit tests, one of which pins the all-zero key against the
10019 digest, since that relationship failing silently is what makes the whole path wrong.
The package builds at the new pin.

**Not verified against hardware.** It cannot be until the sensor holds a key we know.

### A correction to the previous version of this document

It stated that `LIBFPRINT_GOODIXTLS_PSK_HEX` "does nothing on this path". That was true only
because activation was dying at state 4. In `goodix.c`, `goodix_tls()` prefers the
environment key over the driver's own:

```c
if (priv->tls_psk && priv->tls_psk_len) { s->psk = priv->tls_psk; ... }
else if (gx_class->get_tls_psk) { ... }
```

So once the sensor holds the all-zero key, **even the already-installed `r2013` build** would
pass the gate and get a usable key from the environment. Our fix removes the need for the
variable and adds the recovered-key case; it is not a prerequisite for the first test.

---

## 10. Field evidence for what happens next

From the public record. Relevant because it sets expectations for the work *after* the key
problem is solved.

- **Two** end-to-end re-keying runs on a 521d are documented publicly, both successful on the
  first attempt. One is on a ROG Zephyrus GA503QR — same chassis generation, same sensor,
  same firmware. A success *rate* cannot honestly be computed from two samples.
- **No bricked 521d has ever been reported.** The one confirmed brick in the ecosystem is a
  different sensor whose owner wrote a key valid for one firmware and then flashed another.
  That mismatch cannot occur here: the shipped white-box blob encodes the key that the
  shipped image expects.
- Being stuck in the bootloader is recoverable by re-running the tool. The single reported
  case was a missing firmware file, from a clone without submodules.
- **Matching quality is the real risk.** On that GA503QR, enrolment worked only after six
  separate driver patches, and verification then succeeded 3 times in 10, while a *different*
  finger scored 21 against a threshold of 24. Another 521d user reports being able to
  authenticate with fingers they never enrolled. Nobody has published an acceptable-accuracy
  521d result.
- An in-place key write **without** erasing was attempted on a sibling unit and the device
  rejected it at the protocol level, with firmware and digest unchanged. That was on the
  newer firmware, not 10019, so it is strong but not conclusive evidence that the erase is
  unavoidable.
- Merely booting Windows appears not to re-key the sensor; enrolling in Windows Hello does.
  One observation, on a machine whose reader is the power button. Treat as unconfirmed.

---

## 11. Reproducing the current failure

```sh
sudo systemctl stop fprintd
printf '6\n' | G_MESSAGES_DEBUG=all \
  ~/.cache/paru/clone/libfprint-goodixtls52xd-git/src/build/examples/enroll
```

`examples/enroll` reads the finger choice from stdin before opening the device, hence the
piped `6`; without it, it looks like a silent hang.

That build carries the scratch `fp_warn()` patch described in §6, which is what made the two
digests visible. It is no longer needed: the driver in `r2014` reports both digests in the
failure itself, so `journalctl -u fprintd` shows them after installing it. The scratch patch
must never reach the fork.

---

## 12. Open items

In the order `runbook.md` runs them. Items 1 to 3 are reversible; item 4 is not.

1. **Read-only Windows key search.** Not run. Needs root. Would make everything below
   unnecessary if it hits, which it probably will not.
2. **Read-only sensor probe** for firmware, digest and calibration data. Not run. Needs root.
   `tools/prepare-goodix-tool.sh` is done and tested, so this is one command.
3. **Install the rebuilt package**, and restart niri so the polkit agent runs. Neither done.
4. **Re-key the sensor.** Blocked on a decision, not on effort. See `hypothesis.md` §10.
5. **Enrol, then measure** against the criterion in `hypothesis.md` §8 before wiring anything
   to the authentication path.
6. `mise-tasks/fingerprint` — designed, not built. Deliberately deferred until enrolment and
   verification actually work.
7. `[lockscreen] fingerprint = true` in Noctalia's settings — deferred for the same reason.
8. `pam_fprintd.so` for 1Password — a separate decision. CVE-2024-37408 applies to the polkit
   path but not the lock-screen D-Bus path. Keep `pam_fprintd` **out** of `/etc/pam.d/sudo`.

Known and deliberately not fixed: the sibling 5110 and 538d drivers hand a digest to OpenSSL
as if it were a key (§13 item 7), and the four suspect defects in the driver's 10019 scan path
(`hypothesis.md` §7). Both wait on hardware that can exercise them.

---

## 13. Things a fresh reader is likely to get wrong

Each of these already cost time.

1. **Noctalia cannot enrol.** Its binary references `Claim`, `Release`, `VerifyStart`,
   `VerifyStop` and nothing else. Enrolment happens elsewhere.
2. **`noctalia --version` does not tell you what is running.** It execs the on-disk binary.
   Use `readlink /proc/$(pgrep -x noctalia)/exe`; a `(deleted)` suffix means the old process
   is still alive.
3. **Grepping the built `.so` for `521d` finds nothing.** USB IDs are stored as integers.
4. **`makepkg` fails `check()` on a network lint**, not on real failures.
5. **Commits in this repo need `--no-gpg-sign`.**
6. **A successful re-keying run ends in a traceback** (see §8). Judge it by the printed
   `Valid PSK: True`, not by the exit code.
7. **The sibling 5110 and 538d drivers hand the stored digest to OpenSSL as if it were the
   key** — `goodix_511_psk_0` and `goodix_53xd_psk_0` are digests, not keys, and the
   reference implementations use all-zero keys for both. Not fixed here, because neither
   device is present to test against. It is the same defect fixed for 52xd in `ff4f8c0`.
