# HOMESETS — Data Security Threat Model & Privacy Hardening

**Document Status:** [Active Security Architecture]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D02, D13, D18), `docs/PROJECT_RULES.md`  

---

## 1. Security Baseline & Trust Assumptions

HOMESETS operates under strict security and privacy invariants:
- **Trust Boundary:** The app runs on a personal Android device. The user trusts the hardware, but untrusted external applications, cloud scrapers, and malicious backup archives exist in the environment.
- **Zero Network Invariant (D02):** The app declares **zero network permissions** in `AndroidManifest.xml` (`android.permission.INTERNET` is omitted). The app cannot initiate outbound HTTP/TCP connections.

---

## 2. STRIDE Threat Analysis Matrix

| Threat Category | Specific Threat Vector | Risk Level | Mitigation & Architectural Hardening | Verification Method |
| :--- | :--- | :--- | :--- | :--- |
| **Information Disclosure** | Physique photos appear in phone gallery or Google Photos auto-upload. | **CRITICAL** | Store photos in internal sandbox (`getFilesDir()/physique_photos/`); place `.nomedia` file; do not register with `MediaStore`. | Inspection of Google Photos app on real device; verify zero visibility. |
| **Tampering / Code Execution** | Malicious backup archive attempts Zip-Slip path traversal to overwrite app binaries or shared libraries. | **HIGH** | Strict canonical path validation during extraction (`canonicalPath.startsWith(stagingDir)`); reject any `../` entry. | Unit test with synthetic Zip-Slip archive asserting immediate `SecurityException`. |
| **Denial of Service** | Decompressing a "Zip-Bomb" backup exhausts device storage and freezes Android. | **MEDIUM** | Hard ceiling on total uncompressed bytes ($\le 500$ MB) and total file count ($\le 500$ files) during decompression. | Test decompression with synthetic 1 GB expansion payload asserting abort at 500 MB. |
| **Information Disclosure** | Unencrypted Android cloud backup or D2D transfer exports private physique photos. | **HIGH** | Set `allowBackup="false"` AND configure `dataExtractionRules` to disallow cloud backup and device transfer. | Android Manifest lint check; verification of `res/xml/data_extraction_rules.xml`. |
| **Information Disclosure** | User exports unencrypted `.hsbk` backup and uploads to public cloud or messaging app. | **MEDIUM** | Prominent warning modal displayed before export; optional AES-256 password protection in Milestone P7. | UI inspection of export flow confirmation dialog. |
| **Tampering** | Database corruption from unexpected power loss or battery death during workout logging. | **MEDIUM** | SQLite WAL mode enabled; immediate per-set commit transactions; cold `.snap` snapshot during schema upgrades. | Automated crash injection test killing app process mid-transaction. |
| **Elevation of Privilege** | App requests dangerous special Android permissions (Location, Contacts, Camera, Microphone). | **LOW** | Zero extraneous permissions. Only `POST_NOTIFICATIONS` (optional) and photo picker intent (scoped to selected image only). | Manifest permission audit in CI pipeline. |

---

## 3. Manifest Network Lockdown

To provide cryptographic proof of zero cloud tracking or telemetry:
```xml
<!-- In AndroidManifest.xml: -->
<!-- STRICTLY FORBIDDEN: -->
<!-- <uses-permission android:name="android.permission.INTERNET" /> -->
```
By omitting `android.permission.INTERNET`, the Android Linux kernel blocks all socket creation (`socket()`, `connect()`) at the OS syscall level, making data exfiltration impossible even in the presence of accidental third-party library dependencies.
