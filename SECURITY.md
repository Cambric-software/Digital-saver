# Security Policy

## Scope

This policy covers the Digital Saver companion application (`app/`) and the
Veyro smartwatch firmware it talks to (`firmware/`).

It is written to describe what the software **actually does**. Where something
is not protected, it says so plainly rather than implying coverage. An earlier
version of this file claimed that user profiles and emergency contacts were
encrypted and that no data left the device. Neither was true, and a security
document that overstates its own protections is worse than none, so both claims
have been removed and the real behaviour is documented below.

**Digital Saver is not a medical device and is not a certified medical
product.** It displays readings and offers general wellness information. It does
not diagnose, and it must not be relied on in place of professional care.

---

## What data the app handles

| Data | Where it lives | Protection |
| --- | --- | --- |
| Heart rate, HRV, blood pressure, oxygen, activity, sleep | Watch flash, mirrored to the app | Unencrypted at rest |
| User profile: name, email, phone, date of birth, age, weight, height | App preferences, key `veyro_profile` | **Unencrypted at rest** |
| Medical conditions and medications | App preferences, inside `veyro_profile` | **Unencrypted at rest** |
| Emergency contacts and phone numbers | App preferences, key `veyro_contacts` | **Unencrypted at rest** |
| Watch pairing PIN | OS keystore via `flutter_secure_storage` | Encrypted by the operating system |
| App lock PIN | App preferences | Salted PBKDF2-HMAC-SHA256, 120,000 iterations |

Two rows are the important ones. The profile contains medical conditions and
medications, and the contacts list contains the phone numbers someone relies on
in an emergency. Both are stored as **plain text in application preferences**.

This matters because preferences are readable by anything running as the same
user account: a backup that is copied off the device, a synced cloud folder, a
malware process with the user's rights, or disk imagery from a stolen machine.
Application preferences are inside the sandbox, which stops other applications
on a desktop, but sandboxing is not encryption.

**This is the largest known gap in the product.** Encrypting the profile and
contacts at rest is tracked as required work, not as a future consideration.

---

## What leaves the device

The app is local-first: readings are taken from the watch over Bluetooth and
stored on the device. Nothing is uploaded by default.

The exception is the **AI assistant**. When someone asks it a question, the app
sends the following to a remote model provider:

- name, age, gender, BMI
- **medical conditions and medications**
- heart rate, HRV, AFib probability
- blood pressure, oxygen saturation
- activity and sleep
- the text of the question, plus recent turns of the conversation

That request goes to Google's Gemini API either directly with a compile-time
API key, or through a Cloudflare Worker at
`digital-saver-ai.asser-k-dev.workers.dev` when no key is embedded.

So the accurate statement is: **health data stays on the device except when the
person deliberately uses the assistant**, and at that point identifiable health
and medication data is sent to a third party and is subject to that provider's
retention and training policies.

The assistant is opt-in. It is not contacted for any other reason, and no
identifier is sent alongside the readings.

---

## Cryptography in use

- **App lock PIN** — PBKDF2-HMAC-SHA256, a per-install random salt, 120,000
  iterations, compared in constant time. Verification failures are recorded and
  the lock re-arms.
  Legacy hashes, which were unsalted single-pass SHA-256 and could be attacked
  at billions of guesses per second, are **rejected** rather than accepted, so
  an old PIN cannot be unlocked by a weaker path.
- **Package integrity** — downloaded update packages are verified against a
  SHA-256 checksum before they are used. A mismatch aborts the update.
- **Watch pairing PIN** — held in the operating system's credential store.

There is no transport encryption applied by this app beyond the platform's own:
BLE pairing with a PIN, and TLS for the assistant request to Google.

---

## Update mechanism

Updates install into a versioned layout:

```
%LOCALAPPDATA%\Programs\DigitalSaver\/
  current.txt                     the version that should run
  versions/0.1.1/digital_saver.exe
  versions/0.1.2/digital_saver.exe
```

The shortcut points at the version the installer shipped. When an update lands,
that older copy starts first, sees that `current.txt` names a newer version, and
hands over. This exists because replacing a running executable fails on Windows,
and because the previous updater could uninstall the application before
installing an update with no backup — leaving nothing to recover.

On Android the app hands the downloaded APK to the system package installer and
lets the user confirm. It does not attempt a silent install: `pm install`
requires permissions no ordinary application holds, and a build that pretends
otherwise is a build that fails silently and reports success.

---

## BLE transport

The watch is reached over Bluetooth Low Energy and requires a pairing PIN.

Limitations worth stating plainly:

- BLE is a broadcast medium. The link-layer pairing is not equivalent to a
  mutually authenticated session, and traffic on it should be assumed readable
  by an attacker in radio range.
- The firmware and the app are developed together. There is no signed-firmware
  verification in the shipped pairing flow, so a modified watch presenting the
  right identifiers would be accepted.
- Anyone who knows the pairing PIN and is in radio range can pair. There is no
  device allow-list.

---

## Known limitations and gaps

1. **Profile and contacts are unencrypted at rest.** Highest priority. Medical
   conditions, medications and emergency contact numbers are all plaintext.
2. **The assistant transmits identifiable health data** to a third party, with
   no consent prompt beyond the person choosing to use it, and no way to redact
   the medical fields.
3. **No firmware signature verification** on the watch.
4. **No BLE allow-list.** Pairing depends only on knowing the PIN.
5. **Reports go to a personal address.** Security reports are currently
   addressed to an individual rather than a monitored team mailbox, so a report
   can go unread.

---

## Reporting a vulnerability

Email **support@cambric.dev** with:

- what the issue is and which version it affects
- how to reproduce it
- what an attacker gains

Please do not open a public issue for a security problem.

You can expect an acknowledgement within 3 working days and a decision on
whether the report is accepted within 14 days. Confirmed issues are fixed in the
next release, and you will be credited in the release notes unless you ask not
to be.

**If a report reveals a life-safety issue** — a wrong emergency number, a
failing alert, readings shown as trustworthy when they are not — say so in the
subject line, because those are handled as urgent.

---

## Out of scope

The following are not vulnerabilities:

- The app showing a reading without a medical professional having reviewed it.
  It is a wellness tool and says so on screen.
- Cosmetic layout problems, or anything that needs physical access to an
  unlocked device to exploit.
- Denial of service through Bluetooth jamming, which is a property of the radio
  environment rather than of this software.