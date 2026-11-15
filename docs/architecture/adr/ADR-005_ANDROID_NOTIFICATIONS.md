# ADR-005: Android Local Notification Strategy & Background Constraints

- **Status:** Proposed (Honor / MagicOS Verification Pending)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D07, D15, E01, O06), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

Ahmed works an evening shift (7 PM – 4 AM), waking up around 3:00 PM and leaving home around 5:00 PM. A single, respectful workout reminder at ~3:30 PM (`قبل الشغل ⏰`) is planned (D15). 

However, modern Android versions (Android 13+ through Android 16 on Honor X9e Pro / MagicOS 10) enforce aggressive background power-management restrictions:
1. `POST_NOTIFICATIONS` runtime permission is required on Android 13+ (API 33+).
2. Exact alarms (`SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`) are heavily throttled by Google Play and aggressive OEM battery killers (Honor MagicOS / Huawei EMUI).
3. We must determine how to deliver this optional reminder reliably without draining battery or demanding dangerous special permissions.

---

## Decision Drivers

1. **User Respect & No Guilt (D15):** Max 1 optional reminder per day; no spam, no scolding if missed.
2. **Permission Minimalism:** Avoid high-risk permissions (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) unless verified essential.
3. **Inexact vs. Exact Scheduling:** Workout reminders have a $\pm 10$ minute tolerance window; exact-millisecond timing is unnecessary.
4. **Offline Local Execution:** Notifications must be scheduled locally via Android `AlarmManager` or `WorkManager`; zero remote push services (Firebase/OneSignal).

---

## Considered Options

- **Option A: Inexact Daily Local Notifications (`flutter_local_notifications` with inexact alarms)**
  - Uses standard Android inexact recurring alarms or daily WorkManager jobs.
  - Respects Android battery optimization (Doze mode window).
  - Tolerates $\pm 15$ minute timing jitter, which is perfectly acceptable for a "before-work" workout nudge.
- **Option B: Exact Alarms (`SCHEDULE_EXACT_ALARM`)**
  - Requires user to grant special permission in OS settings on Android 14+. High user friction.
- **Option C: Request Battery Optimization Whitelist**
  - Prompt user to disable battery optimizations. Highly intrusive and often rejected by OEM security managers.

---

## Decision Outcome

**Recommended Option:** **Option A: Inexact Daily Local Alarm Scheduling**.

### Implementation Strategy:
1. Schedule a single recurring local notification for 3:30 PM using inexact Android alarms.
2. If the user completes their workout prior to 3:30 PM, the alarm for that day is automatically canceled or suppressed.
3. If notification permission is denied by the user, the app gracefully operates without reminders with zero error prompts.
4. Document Honor MagicOS 10 power management behavior as **UNVERIFIED** until physical acceptance on the real device.
