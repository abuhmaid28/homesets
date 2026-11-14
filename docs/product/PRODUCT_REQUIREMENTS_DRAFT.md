# HOMESETS — Product Requirements Document (Draft Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G1 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)
**Authority Reference:** `docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt`, `docs/DECISION_REGISTER.md` (D01–D20, GOV01–GOV11)

---

## 1. Problem Statement & Job-To-Be-Done

### 1.1 Core Problem
Ahmed wants to build muscle and achieve a defined, athletic physique at home because he cannot rely on a gym due to intense schedule constraints (7:00 PM – 4:00 AM night shift, ~3-hour daily commute). Previous training attempts failed due to:
1. **Decision paralysis:** Unsure what exercises, sets, or reps to perform today without wasting mental energy.
2. **Unclear progression:** Guessing weight/band tension and rep counts without a systematic overload framework.
3. **Slow scale feedback:** Body weight moves slowly (realistic surplus yields ~0.25–0.5 kg/week); without visible physical photo tracking, motivation wanes.
4. **All-or-nothing guilt:** Inflexible rigid schedules and daily streak counters cause abandonment after missed sessions.

### 1.2 Job-To-Be-Done (JTBD)
> *"When I wake up before my night shift with limited time and energy, I want the app to tell me exactly what workout to do in under 3 taps, adapt to my pull-up bar and bands, guide me through sets and rest periods effortlessly with one hand, and visually prove my physical progress over time so I stay consistent without guilt."*

---

## 2. Target User Persona & Constraints

### 2.1 Primary User: Ahmed [Confirmed: D05, D07, D08, D09]
- **Age / Physical Baseline:** 26 years old, 190 cm height, 60 kg body weight. Baseline strength: ~10 pull-ups, ~10 push-ups. No reported joint injuries or physical limitations.
- **Goal:** Reach 80 kg, gain muscle mass, build a defined upper body and broad back.
- **Daily Rhythm:** Wakes ~3:00 PM, departs for work ~5:00 PM. Night shift: 7:00 PM – 4:00 AM. Daily commute: ~3 hours total. Days off: Saturday and Sunday.
- **Workout Windows:** 15–30 minutes, typically before work (between 3:30 PM and 4:45 PM), and the same duration on days off.
- **Available Equipment:** Pull-up bar and resistance bands only. No dumbbells, no barbell, no weighted vest, no backpack loading.
- **Nutrition Context:** Eats ~3 meals/day (liver/cheese sandwiches, pasta, rice, vegetables, pastries, juice). Economical food choices; no calorie counting or macro tracking.
- **Device:** Honor X9e Pro running Android 16 / MagicOS 10. Private wireless APK installation (no USB debugging required for daily use).

### 2.2 Secondary Users (Post-MVP): Friends [Confirmed: D03, D18]
- Friends will install their own standalone APK copies locally.
- Standalone local database per device (zero multi-user sync, no accounts, no cloud).
- May have different equipment (e.g., dumbbells, bodyweight only) and session length preferences.
- *Scope Boundary Note:* Additional goals (fat loss, endurance) are strictly **post-MVP**. MVP onboarding supports the muscle-building goal exclusively.

---

## 3. Product Principles

1. **Three-Tap Start:** From app launch on the Today screen, starting a workout must take at most 3 taps.
2. **One-Handed Ergonomics:** During a workout, all primary actions (rep logging, rest timer control, set completion) sit inside the lower thumb zone with oversized tap targets (minimum 56×56 dp).
3. **Deterministic Rule-Based Progression:** The plan engine advances load systematically via double progression without random AI models or cloud dependencies.
4. **Guilt-Free Consistency:** Weekly session targets (e.g., 3–4 sessions/week) replace daily streak counters. Missing a day causes zero penalty; absences of 7+ days trigger an automatic lighter re-entry session.
5. **Private Physique Tracking:** Progress photos are the primary physical milestone indicator. Photos are saved strictly inside app-private internal storage and never exposed to the public media gallery.
6. **100% Offline & Zero Cost:** Zero network calls, zero backend servers, zero account creation, zero subscriptions.

---

## 4. MVP Feature Specifications

### 4.1 Onboarding & First Launch (Screen 1–4)
- **Goal Selection:** Defaulted to "Build Muscle & Shape" (بناء العضلات والقوة).
- **Physical Profile:** Height (cm), Weight (kg), Age, Push-up & Pull-up baseline rep counts.
- **Equipment Inventory:** Toggle selection: Pull-up bar, Resistance bands, Flat ground / chair.
- **Session Duration:** 15 min, 20 min, 30 min (Default: 20–30 min).
- **Pain / Avoid Areas:** Checklist: Shoulders, Elbows, Wrists, Lower back, Knees. Exercises loading these joints are excluded.
- **Preferences:** Egyptian Arabic (RTL default) or English; Dark theme (default) or Light; Optional daily workout reminder (default 3:30 PM).

### 4.2 Today Screen (Primary Hub)
- **Next Planned Session Card:**
  - Session title and target muscle groups (e.g., "سحب وضهر - اليوم الأول").
  - Estimated duration (15–30 min) and exercise count (3–4 movements).
  - Prominent primary CTA button: **ابدأ التمرين (Start Workout)**.
  - Secondary quick CTA: **تمرين سريع 15 دقيقة (Lite Mode)**.
  - Tertiary action: **تبديل تمرين (Swap Exercise)**.
- **Weekly Consistency Ring:** Shows sessions completed this week versus weekly target (e.g., 3 of 4 completed).
- **Recent Progress Snippet:** Days since last session, latest weight entry.

### 4.3 Workout Player
- **Screen Awake:** Display stays awake during active workout session.
- **Current Exercise Display:**
  - Exercise title in Egyptian Arabic with English name reference.
  - Muscle targets, current set index (e.g., مجموعة 2 من 3).
  - Target rep range (e.g., 8–12 تكرار) and band color/resistance rung.
- **One-Tap Rep Stepper & Logger:**
  - Quick rep adjust buttons (-1 / +1) and direct keypad or large step selector.
  - Log Set Button (تسجيل المجموعة) triggering automatic rest timer.
- **Set Feedback Rating:**
  - Immediately following set log: **سهل (Easy)** | **مظبوط (Right)** | **صعب (Hard)**.
- **Rest Timer:**
  - Visual circular countdown (default 90s for compound, 60s for isolation).
  - +30s / Skip buttons.
  - Sound and haptic vibration pulse upon timer completion.
- **Workout Player Controls:**
  - Skip exercise (تخطي).
  - Swap exercise due to pain or equipment constraint (تبديل).
  - Emergency Pain Stop (وقف التمرين - في ألم).

### 4.4 Workout Summary
- Total duration, total volume (sets completed), exercises logged.
- Congratulatory encouragement in colloquial Egyptian Arabic.
- Next scheduled workout recovery advice (e.g., "عضلات الضهر محتاجة ترتاح 48 ساعة").

### 4.5 Progression & Plan Engine (Pure-Dart)
- **Rotation Structure:** Upper Pull / Upper Push / Legs & Core alternating rotation; no fixed calendar days.
- **Overload Logic (Double Progression):**
  - Step 1: Add reps until reaching top of bracket (e.g., from 8 up to 12 reps) across all sets with "Right" or "Easy" feedback.
  - Step 2: Once top rep target is met cleanly, advance difficulty ladder (e.g., increase band tension or use tempo variation) and reset reps to bottom bracket.
  - Step 3: If "Hard" with falling reps across 2 consecutive sessions, maintain or deload 1 rung.
- **Recovery Spacing:** Primary muscle groups are locked from scheduling for 24–48 hours post-workout.
- **Absence Handling:**
  - 1–6 days missed: Resume rotation seamlessly at next planned session.
  - 7–14 days missed: Insert an automatic lighter re-entry session (-30% volume).
  - 14+ days missed: Propose re-calibration of working rungs.

### 4.6 Progress Hub
- **Progress Photos:**
  - Angles: Front (أمامي), Side (جانبي), Back (خلفي).
  - Capture helper with silhouette outline guide.
  - Side-by-side comparison slider (Compare Date A vs Date B).
  - Fully private storage: Saved in app sandbox directory, excluded from Android MediaScanner.
- **Weight Tracking:**
  - Quick weight logging modal (date + kg to 1 decimal place).
  - Weekly 7-day rolling average line chart (smooths daily water weight fluctuations).
  - Gentle advisory prompts: If weight change < 0.1 kg/week over 3 weeks while on muscle-gain goal, display tips to add an extra meal portion.
- **Strength Charts:**
  - Progress curves for primary benchmark movements (Pull-up rep max, Band push-up tension).
- **Meal Checklist:**
  - 4–5 daily checkboxes (وجبة 1، وجبة 2، وجبة 3، سناك بروتين، شرب مياه).
  - Cheap local protein guide (بيض، كبدة، فول، جبنة قريش، عدس، تونة، لبن).
  - Zero calorie counting, zero macro tracking.

### 4.7 Settings & Utilities
- **Manual Backup & Restore:**
  - Single-file export (JSON data + private images compressed into local archive).
  - Validated import with schema compatibility check and file integrity validation.
- **Reminders:**
  - Single local notification daily (Default 3:30 PM).
  - Uses `flutter_local_notifications` with explicit Android 13+ permission request.
  - Documents Honor MagicOS power saving guidance for the user.
- **Language & Theme:**
  - Arabic (RTL) default, English (LTR) toggle.
  - Dark mode (charcoal + Performance Lime) default; Light mode toggle.
- **Data Privacy & Reset:**
  - Complete "Clear All Data" local reset option with confirmation dialog.

---

## 5. Non-Goals & Explicit MVP Exclusions

| Excluded Feature | Reason for Exclusion |
| :--- | :--- |
| User Accounts & Cloud Authentication | Violates offline-first, private-only principle; zero recurring infrastructure cost. |
| Cloud Database / Real-Time Sync | Unnecessary complexity; user data stays on device. |
| Calorie & Macro Food Database | Causes friction, cognitive fatigue, and eating anxiety; replaced by simple meal checklist. |
| Daily Streaks / Streak Freezes | Causes demotivating guilt after shifts; replaced by weekly consistency ratio. |
| Social Feeds / Community Boards | Out of scope; private personal utility. |
| In-App AI/LLM Execution | High battery/resource usage; deterministic rule engine is 100% predictable and safe. |
| Wearable / Smartwatch Integration | Deferred to post-MVP; phone-only experience for Ahmed. |
| Google Play Store Release | Private personally installed APK distribution only. |
| iOS Build | Ahmed uses Android (Honor X9e Pro); iOS requires Apple Developer fees and hardware. |

---

## 6. Edge Cases & Exception Handling

1. **Interrupted Workout / App Killed Mid-Session:**
   - Active workout state is persisted after every set logged in SQLite/Drift.
   - Upon reopening app, Today screen displays an "استئناف التمرين (Resume Workout)" banner.
   - User can resume seamlessly or discard session.
2. **Pain Reported During Exercise:**
   - User taps "في ألم (Pain)".
   - App prompts: "هل نوقف التمرين ولا نبدل الحركة بحركة بديلة آمنة؟"
   - If swap chosen, engine filters exercise database excluding the active joint group.
   - Records pain event to avoid offering that movement in subsequent sessions until user unblocks it.
3. **Missing / Broken Equipment:**
   - If a band snaps or bar is inaccessible, user taps "تغيير الأدوات المتاحة".
   - Plan engine dynamically recalculates the remaining session using bodyweight/floor variations.
4. **Extreme Inputs in Onboarding:**
   - Weight < 30 kg or > 250 kg, Height < 120 cm or > 230 cm triggers an input validation warning ("تأكد من صحة الرقم المدخل").
   - Max pull-up reps = 0: Engine starts with eccentric negatives and band-assisted variations.
5. **Backup Import Mismatch:**
   - If imported backup version > app schema version, import aborts gracefully with an alert: "ملف النسخة الاحتياطية تم إنشاؤه بإصدار أحدث من التطبيق".

---

## 7. Accessibility, RTL & Ergonomics Requirements

- **Target Touch Targets:** Minimum 48×48 dp for secondary controls; minimum 56×56 dp for workout player primary actions.
- **Contrast Ratios:** Minimum 4.5:1 for body copy; minimum 3:1 for large graphical elements and buttons against dark charcoal background (#121316).
- **RTL Mirroring:** Full Egyptian Arabic layout mirroring. Back navigation arrows, progression bars, and drawer handles mirror appropriately. Directional exercise diagrams and numerical clocks/timers remain LTR/un-mirrored where standard.
- **Arm's Length Legibility:** Workout player displays current exercise and rest countdown in bold display sizes (>=32 sp) readable while standing 1 meter away from phone.

---

## 8. Requirements Traceability to Decision Register

| Requirement Area | Decision Register ID | Status |
| :--- | :--- | :--- |
| Android-only, private APK, no Play Store | D01 | Confirmed |
| Offline-first, local SQLite, zero cost | D02 | Confirmed |
| Single-user private install, friends later | D03, D18 | Confirmed |
| 15–30 min sessions, pre-work routine | D08 | Confirmed |
| Pull-up bar + bands only | D09 | Confirmed |
| Weekly consistency over daily streaks | D11 | Confirmed |
| 15-minute Lite mode | D12 | Confirmed |
| Progress photos primary, no body tape measurements | D13 | Confirmed |
| Meal checklist, no calorie counting | D14 | Confirmed |
| Dark-first, Egyptian Arabic RTL first | D15, D16 | Confirmed |
| Pure-Dart deterministic plan engine | D17 | Confirmed |
| Single final Honor X9e Pro phone acceptance | GOV07, GOV10 | Confirmed |
| Guarded automated CI merge gate | GOV08 | Confirmed |
