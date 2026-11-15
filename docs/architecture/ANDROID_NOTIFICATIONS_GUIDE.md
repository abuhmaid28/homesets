# HOMESETS — Android Notification Architecture & OEM Background Guidance

**Document Status:** [Active Technical Guidance]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Target Platform:** Android 13+ through Android 16 (Honor X9e Pro / MagicOS 10)  
**Authority Reference:** `DECISION_REGISTER.md` (D07, D15, E01, O06), `docs/PROJECT_RULES.md`  

---

## 1. Executive Strategy: Inexact, Respectful, Zero-Spam Reminders

In accordance with Decision D15 and Decision D07:
- The app offers **at most one** daily reminder at ~3:30 PM (`قبل الشغل ⏰`), timed for Ahmed's wake window before his 7:00 PM evening shift.
- The reminder is completely optional. If dismissed or ignored, no follow-up nudges or guilt notifications are sent.
- If a workout is logged prior to 3:30 PM, the reminder is automatically suppressed.

---

## 2. Android OS Permission Architecture (API 33+ / Android 13–16)

### 2.1 Runtime Permission: `android.permission.POST_NOTIFICATIONS`
- On Android 13+ (API 33+) and Android 16 (MagicOS 10), notifications cannot be posted without explicit runtime user consent.
- **Handling Denied Permission:**
  - If the user denies notification permission during onboarding or settings, the app marks `reminders_enabled = false` in SQLite.
  - The app **never** spams the user with popups begging to enable notifications.
  - The entire core workout tracking, offline logging, and progress hub operate with 100% functionality without notifications.

### 2.2 Alarm Scheduling: Inexact vs. Exact Alarms
- Starting in Android 12 (API 31) and Android 14 (API 34), Google heavily restricted `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`. Applications using exact alarms for non-clock/timer functions face Google Play policy violations and aggressive OEM task killing.
- **HOMESETS Policy:**
  - We use standard Android **inexact daily alarms** (`AlarmManager.setInexactRepeating()` or WorkManager periodic requests).
  - Inexact alarms permit the Android OS to batch wakeups with other device tasks, preserving battery life during Doze mode.
  - A timing window of $\pm 10$ minutes around 3:30 PM is 100% acceptable for a general fitness nudge.

---

## 3. OEM Background Battery Killers & MagicOS 10 Unverified Status

### 3.1 The OEM Background Problem
Custom OEM skins (such as Honor MagicOS, Huawei EMUI, Xiaomi HyperOS, Samsung OneUI) frequently kill background alarm managers to show inflated battery endurance numbers.

### 3.2 What We Will NOT Do:
- We will **NOT** demand `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` indiscriminately.
- We will **NOT** instruct the user to disable all system battery protectors on their phone without empirical evidence.

### 3.3 Explicit Verification Status:
> [!NOTE]
> Until the final wireless APK is physically tested on the Product Owner's **Honor X9e Pro running MagicOS 10** (Release Gate / GOV10), the delivery rate of scheduled 3:30 PM reminders remains **UNVERIFIED**.
> 
> If MagicOS 10 silences inexact alarms during deep sleep, a polite in-app settings guide will explain how to whitelist HOMESETS in Honor's "Battery App Launch" manager.
