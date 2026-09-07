# Goodix 27c6:521d fingerprint reader — Hypotheses and routes forward

**Companion to `observations.md`.** That file holds verified facts; this one holds
interpretation, competing theories, proposed fixes and their risks. Read `observations.md`
first — everything here depends on it.

**Confidence labels used below:** *established* (proven by measurement or source), *likely*
(strong indirect evidence), *speculative* (plausible, untested).

---

## 1. The blocker, stated precisely

Driver activation aborts at SSM state 4 (`ACTIVATE_CHECK_PSK`) because the sensor's stored
`sha256(PSK)` is `163ec2b1…`, while the driver, having read firmware
`GFUSB_GM168SEC_APP_10019`, demands `66687aad…` (= `sha256(32 zero bytes)`).

Everything before that state succeeds. The device is detected, claimed and opened. This is
**not** a detection or a kernel problem; it is a key-agreement problem.

---

## 2. Central hypothesis

> **This sensor was provisioned with a PSK that is neither of the two the driver knows.**
> *(established — the hash is measured, and matches neither constant nor any of 267
> candidates.)*

The Goodix TLS design has the host and sensor share a pre-shared key. The sensor stores
`sha256(PSK)` so a host can check "do I have the right key?" before attempting a handshake.
Ours answers "no".

### Why the driver has two firmware branches

*Likely.* Reading `goodix52xd_set_expected_pmk_hash()` and `goodix52xd_get_tls_psk()`
together tells a story:

- For **10034**, the driver holds both the PSK *and* its hash as constants. Self-contained.
- For **10019**, it holds **only the hash** — `get_tls_psk()` returns `NULL`. Even on a
  successful hash check, TLS would have no key.

The only way the 10019 path can ever work is with `LIBFPRINT_GOODIXTLS_PSK_HEX` supplying
the key. That environment variable is not a debugging leftover; it is *the* 10019 mechanism.

**Inference:** 10019 units do not share a universal PSK. The upstream author supported them
by letting the user provide the key, and hard-coded only the all-zeros default that
un-provisioned units ship with. Ours is provisioned, so the default no longer applies.

### Where our PSK came from

*Speculative, but the most economical explanation.* The machine dual-boots Windows
(`observations.md` §2). The Goodix Windows driver performs the same TLS handshake, so it
must possess this PSK. Either:

- **(a)** the vendor ships a per-model PSK inside the Windows driver, or
- **(b)** the Windows driver generated a per-unit PSK and wrote it to the sensor with
  `preset_psk_write` during Windows Hello setup.

These have very different consequences and the next experiment distinguishes them.

### Competing explanation, considered and rejected

*Could the firmware→hash mapping simply be inverted — i.e. our unit reports 10019 but holds
the 10034 key?* **No.** `sha256(goodix_52xd_psk_10034)` was computed and does not equal
`163ec2b1…`. This would have been the cheapest possible fix; it is ruled out.

### On `MCU has no config`

*Likely benign.* It appears three times before the PSK check. Config upload happens at
`ACTIVATE_SET_MCU_CONFIG`, which is **state 8** — after the PSK gate. The MCU legitimately
has no config yet at that point. It is a symptom of stopping early, not a second fault.
Worth revisiting only if the PSK problem is solved and activation then fails later.

---

## 3. Route C — recover the PSK from the Windows driver *(recommended first)*

**Risk: none.** Read-only. Cannot modify Windows or the sensor.

If hypothesis (a) holds, the PSK is a 32-byte literal in a Goodix driver file on
`nvme0n1p2`. Search for a 32-byte window whose `sha256` is `163ec2b1…`.

```sh
sudo /home/a_merii/.config/claude/jobs/aa87c10b/tmp/find-psk.sh
```

The script mounts `nvme0n1p2` with `-o ro` (never `rw`, no journal replay), scans
`DriverStore/FileRepository`, `WinBioPlugIns` and `drivers` for Goodix/WinBio files, slides
a 32-byte window over each, then unmounts.

**If it matches** — this is the clean win. We would then have the actual PSK, and the fix is
small, contained, and requires *no hardware modification whatsoever*:

1. Store the PSK outside the repo (it is a device credential — see §7).
2. Make the activation gate tolerate an externally-supplied key. The minimal change is in
   `check_preset_psk_read()`: when `LIBFPRINT_GOODIXTLS_PSK_HEX` is set, compare the
   device's hash against `sha256(that PSK)` instead of the compiled-in constant, and fail
   only if *that* mismatches. This preserves the existing safety property (never attempt a
   handshake with a key the device does not hold) while removing the false assumption that
   10019 implies all-zeros.
3. Ensure `fprintd` sees the variable — a systemd drop-in on `fprintd.service`, since
   fprintd is D-Bus activated and will not inherit a shell environment.

**If it does not match**, that is evidence for hypothesis (b) — per-unit provisioning, or an
obfuscated/"white-box" key. Goodix is known to ship white-box schemes in some drivers, in
which case the key is computed rather than stored and this search cannot find it.
*Speculative.*

### Fallback within Route C

*Speculative, higher effort.* Capture the Windows↔sensor USB traffic under Windows
(USBPcap/Wireshark) during a Hello scan. Note this yields the *handshake*, not the PSK
directly — the PSK is never transmitted. It would, however, confirm which flags/commands
Windows uses and whether it ever issues `preset_psk_write`. Useful mainly as evidence for
(a) vs (b), not as a way to obtain the key.

---

## 4. Route A — provision a known PSK onto the sensor

**Risk: high. Persistent hardware modification. Would very likely break Windows Hello.**

Write 32 zero bytes with `preset_psk_write`, making the stored hash `66687aad…` — exactly
what the driver already expects for 10019. Then supply the same all-zeros key via
`LIBFPRINT_GOODIXTLS_PSK_HEX` so the handshake has a key.

Attractive because it needs no secret and lands on the driver's existing expectation.

**Why it is second, not first:**

- `goodix_send_preset_psk_write()` has **zero callers in the entire tree**. No driver here
  exercises it. It is protocol support, not a tested path. *(established)*
- Unknown whether 10019 firmware permits the write at all — it may be locked, or may
  require an unlock/authentication step we have not identified. *(speculative)*
- It overwrites the key Windows relies on. Windows Hello would stop working on this sensor
  and would need to re-provision — which it may or may not do automatically. Since the
  machine genuinely dual-boots, this is a real cost, not a theoretical one.
- A failed or partial write could leave the sensor unusable by *both* operating systems.
  Current state is "broken on Linux, working on Windows"; a bad outcome here is "broken on
  both". *(speculative but plausible)*

**Do not attempt without explicit user consent**, having stated the Windows Hello
consequence. Requires a code change in the fork.

If pursued: implement as a **separate, explicitly-invoked tool**, not as a step inside
normal activation. A driver that silently rewrites keys on any hash mismatch would be
dangerous — it would clobber a working Windows provisioning the first time someone plugged
in a mismatched sensor.

---

## 5. Route B — flash firmware to 10034

**Risk: high, irreversible.**

10034 is the fork's tested production target, with both PSK and hash compiled in and a
config-upload path already tuned for it (`goodix52xd_send_upload_config()` patches three
bytes for 10034). If the sensor ran 10034 with the vendor's stock provisioning, the driver
should work as designed.

Against it:

- Requires the vendor/ASUS updater, realistically from Windows.
- *Speculative:* a firmware update probably re-provisions the PSK — possibly to the 10034
  constant (which would fix everything), possibly to another per-unit value (which would
  leave us exactly where we are, having taken an irreversible risk).
- Firmware flashing a security peripheral has genuine bricking potential.

Reasonable only if C fails and A is rejected or proves impossible. Verify first that an
ASUS/Goodix firmware update for GA503QS actually exists and targets `10034`.

---

## 6. Recommended order

1. **Run `find-psk.sh`** (Route C). Zero risk, potentially total resolution. *Nothing else
   should be attempted first.*
2. If matched → implement the gate fix in `AH-Merii/libfprint`, bump the PKGBUILD pin, test,
   then proceed to enrollment.
3. If not matched → report back and decide **A vs B with the user explicitly**, having laid
   out the Windows Hello cost. Do not pick unilaterally.
4. Only once enrollment *and* verification succeed: build `mise-tasks/fingerprint`, then set
   `[lockscreen] fingerprint = true`.

Ordering principle already agreed with the user: **detect → install → enroll → verify →
*then* configure.** Do not write configuration for a capability not yet demonstrated.

---

## 7. Handling the PSK if recovered

*Judgement, not established practice.*

The PSK is a credential that authenticates the host to this specific sensor. Treat it
accordingly:

- **Do not commit it to the dotfiles repo**, which is public. This is the main reason the
  fix should read from the environment rather than bake in a constant.
- Prefer a root-owned `0600` file referenced by an `fprintd.service` drop-in.
- Its value is bounded — it authorises talking to *your* fingerprint sensor, and physical
  access defeats it anyway — but it does not belong in git.

If the fix is contributed upstream, the environment-override approach generalises to any
10019 unit, whereas a hard-coded key would be wrong for everyone else. Worth framing that
way if a PR is ever opened against `djnz00/libfprint`.

---

## 8. Secondary problem — polkit denies unprivileged enroll

Not blocking (root reaches the same failure), but must be solved before a user-facing
enrollment flow exists.

Facts: policy is `auth_self_keep` for active sessions; the session *is* active on `seat0`;
no prompt appeared. *(established)*

Candidate explanations, all *speculative* and untested:

- **No polkit authentication agent is running in the niri session.** Most likely. Noctalia
  may not provide one, and niri does not start one by default. Test:
  `busctl --user list | grep -i polkit`, or check for a
  `org.freedesktop.PolicyKit1.AuthenticationAgent` registration. Fix: autostart an agent
  (e.g. `polkit-gnome`, `lxqt-policykit`, or `mate-polkit`) from
  `desktop/niri/.config/niri/cfg/autostart.kdl`.
- The agent exists but cannot display on the Wayland session.
- fprintd cannot associate the D-Bus caller with the logged-in session.

Diagnose the agent question first; it explains the symptom completely and is cheap to check.

Note this is likely worth fixing on its own merits — a session with no polkit agent will
silently deny *many* privileged operations, not just fingerprint enrollment.

---

## 9. What "done" requires

Even after the PSK problem is solved, the following remain:

- **Enrollment must happen outside Noctalia.** Noctalia v5.0.1 references only `Claim`,
  `Release`, `VerifyStart`, `VerifyStop` — no enroll method exists in the binary. It is a
  verify-only consumer. *(established)*
- Image-stitching sensor: the 521d is 64×80 px and stitches roughly ten captures, so
  enrollment needs many passes and verification may be less reliable than a match-on-chip
  reader. Set expectations accordingly. *(likely)*
- 1Password integration is a **separate decision** with its own risk (CVE-2024-37408), and
  should not be bundled into the lock-screen work.

---

## 10. Things a fresh reader is likely to get wrong

Collected because each already cost time in this investigation:

1. **`LIBFPRINT_GOODIXTLS_PSK_HEX` does nothing today.** It is read in `goodix_tls()`, which
   runs only *after* the activation SSM succeeds. Setting it and re-testing proves nothing
   until the gate at state 4 is changed.
2. **`noctalia --version` does not tell you what is running.** It execs the on-disk binary.
   Use `readlink /proc/$(pgrep -x noctalia)/exe`.
3. **Grepping the built `.so` for the string `521d` returns nothing.** USB IDs are stored as
   binary integers. Read `goodix52xd.h:76` instead.
4. **`fprintd-list` reporting "No devices available" may mean the fork is not installed.**
   Check `pacman -Q libfprint*`; paru will happily satisfy `fprintd`'s dependency with
   stock `libfprint`, which has no 521d support.
5. **`makepkg` fails `check()` on a network lint** (`metainfo-validate`), not on real test
   failures. 127/128 pass.
6. **`examples/enroll` blocks on an interactive prompt before opening the device.** Pipe a
   finger index into stdin or it will look like a silent hang.
7. **Commits in this repo need `--no-gpg-sign`** — `commit.gpgsign=true` is set globally but
   `user.signingkey` is stripped from tracked config, so commits abort otherwise.
