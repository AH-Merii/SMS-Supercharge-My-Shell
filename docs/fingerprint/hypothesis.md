# Goodix 27c6:521d — Interpretation and routes

**Companion to `observations.md`**, which holds verified facts. This file holds
interpretation, competing theories and risk. `runbook.md` holds the ordered procedure.

**Confidence labels:** *established* (proven by measurement or primary source), *likely*
(strong indirect evidence), *speculative* (plausible, untested).

---

## 1. The blocker, stated precisely

Activation aborts at `ACTIVATE_CHECK_PSK` because the sensor's stored `sha256(key)` is
`163ec2b1…`, while the driver, having read firmware `GFUSB_GM168SEC_APP_10019`, expects
`66687aad…`, which is `sha256` of 32 zero bytes.

This is not a detection problem and not a kernel problem. It is a key-agreement problem, and
the two parties disagree about which key they share.

---

## 2. Central hypothesis

> **Windows Hello wrote a random key to this sensor, and that key exists in exactly one
> place we cannot read.** *(likely, and now well supported)*

The Goodix Windows driver implements trust-on-first-use: when it cannot decrypt its stored
copy of the key, it generates a fresh random one and writes it to the sensor. Its own debug
symbols spell out the sequence. *(established, from a published reverse-engineering trace and
the driver's own log strings.)*

This explains the one thing that otherwise looks strange: the sensor runs the stock community
firmware yet holds a digest matching nothing. It was re-keyed in place, without a reflash.

### What this changes about the previous conclusion

The earlier version of this document treated the situation as close to hopeless, because the
key cannot be recovered from its digest. That remains true. But it framed writing a key as an
untested, dangerous path with "zero callers", which was true only *within libfprint*. The
community tool does exactly this, routinely, for exactly this device, and it is the documented
procedure the sensor's Linux support has always depended on. *(established.)*

So the real question was never "can the key be replaced" but "should it be, given what
replacing it costs".

---

## 3. Route A — recover the existing key from Windows

**Risk: none. Read-only. Cannot modify Windows or the sensor.**
**Prior: poor. Do it anyway, because it is cheap and it is the only route that preserves
Windows Hello.**

If the key can be read from the Windows install, nothing needs to be overwritten. Both
operating systems keep working, and the driver change already committed is exactly the
mechanism that consumes such a key.

There is a real precedent: on a sibling Goodix sensor, someone recovered the Windows-written
key from a vendor cache file under `C:\ProgramData\Goodix\` via the machine-scope key
protection state, installed it on the Linux side, and now runs both systems on the same
sensor with no write and no reflash. *(established for that sensor; applicability here is
speculative — that sensor is a different generation with a different driver.)*

Against it:

- On a near-identical ASUS machine with this exact sensor, an exhaustive plaintext search
  over 111 MB — the registry hives, both template stores, and the entire vendor data
  directory — found nothing. *(established.)* So the plaintext case is close to settled
  negative before we start.
- That machine's only wrapped-key candidate sat under Microsoft's biometric subsystem rather
  than the vendor's own keys, shared a protection key with the template database, and is more
  plausibly the template store's own key than the sensor key. *(likely.)*
- The vendor's own cache file on that machine showed no wrapping marker at all.

**Why run it regardless:** it costs one read-only mount, it is the last moment at which the
answer is obtainable, and the machines are not identical. Driver versions differ, and the
file that mattered on the sibling sensor may or may not exist here. Once the key is
overwritten, this question can never be asked about this unit again.

Tooling: `tools/collect-windows-psk-evidence.sh` then `tools/check-psk-candidates.py`.

> The earlier `find-psk.sh` is superseded and should not be used. It searched only for a
> plaintext literal, and only under `System32` — it never looked at the vendor's data
> directory, which is the one place the successful recovery actually happened.

---

## 4. Route B — re-key the sensor to the all-zero key *(the realistic route)*

**Risk: moderate and bounded. Irreversible with respect to the existing key.**

Erase the app firmware, which drops the sensor to its bootloader; write the white-box blob,
which sets the key to 32 zero bytes; reflash the same firmware version the sensor already
runs. The sensor then reports `66687aad…`, which is what the driver expects.

**Why the erase is needed at all.** *(likely.)* The firmware image is cryptographically bound
to the key: the tool derives a key-dependent value and computes an authentication code over
the firmware, which the sensor verifies. Changing the key therefore means flashing an image
whose code matches the new key. Consistent with this, an in-place write without erasing was
attempted on a sibling unit and the device rejected it outright. *(established for that unit,
on newer firmware.)*

**What makes the risk bounded:**

- The bootloader lives at a different level from the app firmware, so a failed app flash
  leaves a device that still answers. *(likely — stated by the tool's author, and consistent
  with two successful runs, but nobody has demonstrated it by deliberately failing a flash.
  This is the single assumption the whole "recoverable" claim rests on.)*
- The recovery image is verified and held locally *before* anything is erased.
- The tool's own loop re-erases on failure specifically so the device stays cleanly in the
  bootloader rather than half-flashed.
- No 521d has ever been reported bricked.

**What it costs:** Windows Hello stops working. And the cost recurs — see §6.

---

## 5. Route C — move to the newer firmware

**Not available, and the reason usually given for wanting it is wrong.**

The newer 10034 firmware is the one the driver fork is actually tested against, and its
branch derives sensor parameters from the unit's own calibration data rather than hardcoding
them. That is genuinely attractive.

But no public image exists. The only known source is the vendor DLL inside this machine's own
Windows driver store. *(established.)*

And the common justification — that the newer firmware survives dual-booting — is false. The
author who first suggested it withdrew it: Windows generates a fresh key per provisioning
regardless of firmware version. *(established.)*

Worth doing anyway, as a side effect of Route A: copy that one DLL off the partition during
the same read-only mount. It costs nothing and removes any future dependency on keeping the
Windows install around.

---

## 6. The cost is recurring, not one-time

*(likely, and understated in the earlier version of this document.)*

Enrolling a finger in Windows Hello re-keys the sensor, and reportedly also moves it to the
newer firmware with a fresh random key. At that point **neither** of the driver's paths works:
the 10019 path no longer applies, and the 10034 path expects a key whose digest matches
nothing the sensor now holds.

Recovery each time is the full cycle: stop the daemon, reset the USB device, erase, write,
reflash, restart. So this is a standing maintenance obligation on the authentication path,
not a one-time cost — on a machine whose vendor utilities install drivers unattended.

Merely booting Windows appears **not** to re-key it; only enrolling does. *(speculative, one
observation, on different hardware.)*

The usual mitigation is disabling the sensor in Windows Device Manager. It is repeated
everywhere and **nobody has reported testing whether it survives a Windows update**. Treat it
as untested advice.

---

## 7. What will probably fail *after* the key problem is solved

This matters for expectations: the key is blocker one of several, and the code path we are
moving the sensor onto is the less-tested of the driver's two.

The 10019 branch of this driver has never executed past the TLS gate on anyone's hardware,
because until commit `ff4f8c0` it could not — it supplied no key. So everything downstream is
unexercised. Four concrete suspects, in the order they would bite:

1. **The reset-number check** is stricter than the reference implementation, which checks only
   a success flag. If this unit answers with a different number, activation dies immediately
   after the gate starts passing. *(established as a difference; low risk, since the sibling
   driver has the same check and works.)*
2. **Two setup calls the reference makes are gated off for 10019** — a post-handshake config
   upload and a driver-state command. The driver's author needed both for the newer firmware
   and then excluded them here. Likely failure: activation reports success and every capture
   comes back blank. *(likely.)*
3. **The blank-frame detection thresholds were tuned against the newer firmware**, which
   uploads a different sensor configuration. If a real finger lands inside the "blank" band
   the driver waits forever; if a blank frame lands outside it, an empty image goes to the
   matcher. *(likely.)* The driver has a frame-dump facility and logs frame statistics; that
   is how to re-tune it.
4. **The image window bytes disagree with the reference implementation.** One reviewer read
   this as a defect; another pointed out the same code has produced real images in the field
   on this firmware. *(contested — do not spend the first debugging session here.)*

Deliberately **not** pre-emptively changed. Each is a guess until there is a device that can
reach that code, and changing several at once makes the first real run uninterpretable.

---

## 8. Decide the accept criterion before spending the irreversible step

The only quantitative results published for this sensor under libfprint come from the same
chassis generation: enrolment worked only after six driver patches, then verification
succeeded 3 times in 10, while a **different** finger scored 21 against a threshold of 24.
Another user reports authenticating with fingers they never enrolled.

That is a reader which mostly fails to recognise its owner and sometimes accepts other people.
Lowering the threshold to fix the first makes the second worse.

**Criterion, fixed in advance so that sunk cost cannot argue it down:**

> Wire the sensor into the lock screen only if, at the driver's stock threshold, an enrolled
> finger verifies at least 8 times in 10, **and** two other fingers produce zero acceptances
> across 10 attempts each.
>
> If it does not meet that, stop. Do not lower the threshold, and do not put it on the
> authentication path. A reader that lets the wrong finger in is worse than no reader.

This is also why the 1Password and `pam_fprintd` questions stay deferred: they put biometrics
on a privilege-escalation path, and that decision should not be made on the momentum of
having got enrolment working.

---

## 9. Handling a key, if one is ever recovered or written

- **Never commit it.** This repository is public. That is the main reason the driver reads the
  key from the environment rather than baking in a constant.
- Prefer a root-owned `0600` file, referenced by a systemd drop-in on `fprintd.service`.
  `fprintd` is D-Bus activated and will not inherit a shell environment.
- Its value is bounded: it authorises talking to *this* sensor, and physical access defeats it
  anyway. It still does not belong in git.
- The all-zero key is not a secret at all. It is a published constant, and a sensor holding it
  offers no protection against a local attacker — worth knowing, though it does not change the
  decision, since the alternative is a sensor that does not work.

---

## 10. The pending decision

Recorded because the work stopped here, and whoever resumes should not have to reconstruct
what was being asked or re-open a question that was already settled.

**Everything reversible has been done.** The driver defect is fixed and pinned, the package is
built, the polkit cause is found and fixed, the recovery firmware is verified and stored, the
tooling is written and tested. What remains needs root, and one step of it cannot be undone.

**The question is whether to overwrite the key Windows wrote to this sensor.** There is no
version of "make this sensor work on Linux" that avoids it, unless the read-only search in §3
finds the existing key, which is unlikely.

Answering it means accepting three things:

1. **Windows Hello stops working on this machine.** Not temporarily. It works again only by
   letting Windows re-key the sensor, which breaks Linux again.
2. **The cost recurs.** Every Windows Hello enrolment means repeating the whole re-keying
   cycle on the Linux side. This is a standing obligation, on the authentication path, on a
   laptop whose vendor tools install drivers unattended.
3. **It may not be worth it.** The published accuracy for this sensor under libfprint is a
   reader that recognised its owner 3 times in 10 while a different finger scored 21 against a
   threshold of 24. The criterion in §8 exists so that this is judged on measurement rather
   than on the momentum of having got this far.

**What was not decided and should not be assumed:** whether that trade is acceptable. It
depends on how much the Windows install is actually used, which is not something the evidence
here can answer.

**If the answer is yes**, `runbook.md` steps 1 through 7 are the procedure, in that order. The
ordering is the safety property, not a formality.

**If the answer is no**, the work already committed is not wasted. The driver fix is correct
independently and upstreamable, the polkit fix solves a session-wide problem that had nothing
to do with fingerprints, and the recovery firmware is stored against the day the answer
changes. Nothing needs reverting.
