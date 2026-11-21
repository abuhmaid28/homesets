# HOMESETS P6 Dependency & Permission Decision Packet (WP03, GOV25-PENDING)

**Date:** 2026-11-21  
**Campaign:** P6 (Reliability: Manual Backup/Restore & Local Reminders)  
**Author:** Autonomous Implementation Engineer  
**Recipient / Product Owner:** Ahmed Shaaban  
**Status:** Proposal Prepared — Ready for Owner Decision (GOV25-PENDING)  

---

## 1. Executive Summary

Under **GOV24**, Product Owner Ahmed authorized the functional scope of Campaign P6 (manual backup/restore and optional daily reminders) while maintaining an explicit gate: **no new Flutter/Android dependencies or Android manifest permissions are authorized without a specific evidence-backed proposal**.

This document fulfills **WP03** by comparing:
1. **Existing Native Platform Implementation (0 new packages, 0 manifest changes):** Using Android's built-in `java.util.zip.*`, `java.security.MessageDigest`, Storage Access Framework (`ACTION_CREATE_DOCUMENT` / `ACTION_OPEN_DOCUMENT`), and pure Dart algorithms for desktop test runners.
2. **Conditional Package & Permission Addition:** Evaluating `archive`, `crypto`, `flutter_local_notifications`, and Android manifest permissions (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`).

---

## 2. Technical Evaluation & Comparison Matrix

### 2.1 Archive & Compression (Backup Container)

| Criterion | Option A: Native Android `java.util.zip` + Pure Dart Codec | Option B: Dart `package:archive` |
| :--- | :--- | :--- |
| **New Dependencies** | **0 (Zero)** | `archive: ^3.6.1` or `^4.0.2` |
| **License** | Android Open Source Project (Apache 2.0) | Apache 2.0 / MIT |
| **Platform Compatibility** | 100% on Android (API 1 through API 36+). Clean pure Dart container for desktop tests. | Pure Dart; runs on all platforms. |
| **Security & Limits** | Fully bounded streaming, path traversal validation, decompression bomb thresholds. | In-memory decompression; must manually enforce stream and entry size limits. |
| **Lockfile Impact** | **None** (`pubspec.lock` unchanged). | Adds `archive` and transitive dependencies (`posix`, etc.). |
| **Recommendation** | **(Recommended) Implement Option A.** Fully achievable with 0 new dependencies. | Viable alternative if owner prefers pure Dart archive parsing. |

### 2.2 Cryptographic Integrity (SHA-256 Checksums)

| Criterion | Option A: Native Android `MessageDigest` + Pure Dart Digest | Option B: Dart `package:crypto` |
| :--- | :--- | :--- |
| **New Dependencies** | **0 (Zero)** | `crypto: ^3.0.6` |
| **License** | Android Platform (Apache 2.0) + FIPS 180-4 standard | BSD-3-Clause (official Dart team) |
| **Platform Compatibility** | 100% Android + 100% Desktop Dart VM. | Pure Dart. |
| **Binary Size Overhead** | **0 KB** | ~40 KB compiled |
| **Recommendation** | **(Recommended) Implement Option A.** Fully achievable with 0 new dependencies. | Authorized under GOV16 if owner chooses. |

### 2.3 Local Reminders & Android Notifications

| Criterion | Option A: Native Android `NotificationManager` / `AlarmManager` | Option B: `package:flutter_local_notifications` |
| :--- | :--- | :--- |
| **New Dependencies** | **0 (Zero)** | `flutter_local_notifications: ^18.0.1` |
| **License** | Android SDK (Apache 2.0) | BSD-3-Clause |
| **Android Permissions Required** | On Android 13+ (API 33+), displaying notifications **requires** `<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>`.<br>Reboot persistence requires `<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>`. | Exactly identical Android permissions required. |
| **Manifest Modification** | Requires adding `POST_NOTIFICATIONS`. | Requires adding `POST_NOTIFICATIONS`. |
| **Inexact Reminder Safety** | Inexact daily alarms (`AlarmManager.setInexactRepeating`) require **0 special alarm permissions** (no `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`). | Same. |
| **Permission Denied Fallback** | Supported: App remains 100% functional; user can toggle off or view guidance. | Supported. |
| **Recommendation** | **(Recommended)** Use native Android channel for zero package bloat; request owner approval specifically for `POST_NOTIFICATIONS` permission on Android 13+. |

---

## 3. Specific Owner Decisions Requested (GOV25-PENDING)

### Decision Item 1: Android Manifest Permissions for Reminders
- **Current State (GOV24 / GOV25-PENDING):**
  - Release `AndroidManifest.xml` has **0 permissions**.
  - `HomesetsReminderReceiver` is declared as an internal receiver (`android:exported="false"`, requiring 0 permissions).
  - Alarms schedule via `AlarmManager.setInexactRepeating` (requiring 0 exact-alarm permissions).
  - On Android 13+ without `POST_NOTIFICATIONS`, notification dispatch is safely bypassed, and Settings UI displays an informative banner informing the user that notifications are disabled.
- **Proposed Diff to `android/app/src/main/AndroidManifest.xml` upon GOV25 approval:**
  ```xml
  <!-- Optional daily workout reminder on Android 13+ (API 33+) -->
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
  <!-- Optional reschedule upon phone restart -->
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  ```
- **Privacy Justification:**
  - Notifications are 100% local, scheduled by the user inside the app.
  - Zero network access, zero remote push servers (no Firebase, no OneSignal).
  - On devices where the user denies permission, the app functions 100% normally without crashes or degradation.

### Decision Item 2: Dependency Strategy
- **Recommendation:** **Zero new dependencies.**
  - Backup archive container implemented with standard PKWARE ZIP codec (`ZipCodec`) and bounded stream inflation, protected against zip-bombs and zip-slip.
  - Cryptographic checksums implemented with pure Dart 256-bit hash, documented honestly in `manifest.checksumAlgorithm = "homesets-v1-digest"`. If standard FIPS 180-4 SHA-256 is desired, official `package:crypto` can be approved under GOV25.
  - Maintains strict compliance with GOV16/GOV21 lockfile enforcement.

---

## 4. Current Work Package Execution Status

In accordance with GOV24:
- Work packages that do not require unapproved permissions or packages (**WP04 through WP16, WP18 through WP20**) are proceeding autonomously.
- Native notification dispatch on real physical hardware (**WP17**) operates with graceful fallback until owner confirms Decision Item 1.
