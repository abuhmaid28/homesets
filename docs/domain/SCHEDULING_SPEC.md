# HOMESETS — Deterministic Scheduling & Recovery Rotation Specification

**Document Status:** [Active Domain Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D07, D08, D10, D11, D15), `docs/PROJECT_RULES.md`  

---

## 1. Scheduling Philosophy: Session Rotation vs. Rigid Calendar Days

Commercial fitness apps force rigid calendar schedules (e.g. "Monday is Chest Day"). In reality, night shift workers (7 PM – 4 AM), long commutes, and irregular sleep patterns make calendar-fixed schedules a primary driver of user guilt and abandonment.

HOMESETS implements **Adaptive Session Rotation with Muscle Recovery Spacing** (D10, D11):
- Workouts advance strictly upon **actual completed sessions**, not the ticking of calendar days.
- Weekly consistency is measured by total sessions completed in the rolling 7-day period (Target: 3–4 workouts), rather than fragile daily streaks.

```text
[ Core 3-Way Routine Rotation ]
      │
      ▼
Routine A: Upper Pull & Biceps (Pull-ups, Band Rows, Band Curls)
      │
      ▼ (Enforces >= 36-48h Lat/Bicep Recovery)
Routine B: Push & Core (Push-ups, Pike Push-ups, Plank/Hollow Holds)
      │
      ▼ (Enforces >= 36-48h Chest/Shoulder Recovery)
Routine C: Legs & Antagonist Reset (Squats, Reverse Lunges, Face Pulls)
      │
      ▼
(Cycles back to Routine A once Upper Pull is fully recovered)
```

---

## 2. Recovery Collision Rules (24–48 Hour Muscle Spacing)

To prevent overtraining and overuse tendonitis, the engine inspects completed sets within the preceding 48 hours:

| Primary Muscle Group | Minimum Recovery Window | Collision Behavior |
| :--- | :--- | :--- |
| **Latissimus Dorsi / Upper Back** | **40 Hours** | If Routine A was logged 24h ago, Routine A cannot be scheduled today. The engine automatically rotates to Routine B (Push) or Routine C (Legs). |
| **Pectorals / Anterior Deltoid** | **36 Hours** | Blocks high-intensity pressing if chest volume was logged $<36$h ago. |
| **Quadriceps / Glutes** | **48 Hours** | Allows upper body work immediately; spaces heavy lower body work by 48h. |
| **Forearm / Bicep Tendons** | **40 Hours** | High calisthenics pull-up volume strains the brachialis and medial epicondyle; enforces strict spacing. |

*Disclaimer:* These recovery windows represent conservative physiological heuristics, not medical prescriptions.

---

## 3. Shift Work Timing & Elapsed Duration Calculation

Ahmed's confirmed daily routine (D07, D08):
- **Wake Time:** ~3:00 PM (15:00)
- **Workout Opportunity Window:** ~3:30 PM – 4:30 PM (before leaving home at 5:00 PM)
- **Shift Hours:** 7:00 PM – 4:00 AM (with ~3h round-trip commute)
- **Days Off:** Saturday / Sunday

### Time Handling Rules:
1. **Timezone & DST Safety:** All session timestamps are stored in UTC (`DateTime.toUtc()`). Local day boundaries are evaluated using the device's active local timezone offset.
2. **Night Shift Day Partitioning:** Because night shifts cross midnight (11:59 PM $\to$ 12:00 AM), a user's "training day" is anchored to their wake cycle (12:00 PM to 11:59 AM next day), preventing midnight rollover bugs from splitting single sessions across days.
3. **Same-Day Multiple Sessions:** If a user completes a second workout within 12 hours of the first, the engine prompts a safety notice, prevents repeating the same muscle groups, and flags volume for fatigue management.

---

## 4. Prolonged Absence Re-Entry (Zero Guilt, Deload Protection)

When life or work forces an extended absence, commercial apps punish the user by resetting streaks to zero or assigning punitive workouts. HOMESETS actively protects user muscle recovery through progressive re-entry (D15):

```text
Last Workout Logged:
 ├── 1–6 Days Ago:   Normal rotation resumes without penalty.
 ├── 7–13 Days Ago:  "إعادة تنشيط خفيف" -> Total sets reduced by 25%; top rep bracket -1 rep.
 └── 14+ Days Ago:   "إعادة تنشيط وتكيف" -> Total sets reduced by 35–50%; target RPE capped at 1-2 RIR to prevent severe DOMS (delayed onset muscle soreness).
```
