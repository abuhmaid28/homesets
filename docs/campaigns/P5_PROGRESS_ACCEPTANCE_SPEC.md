# HOMESETS P5 Progress Tracking — Architectural & Privacy Acceptance Specification

**Campaign:** P5 (Progress Tracking)  
**Issue:** [#15](https://github.com/abuhmaid28/homesets/issues/15)  
**Authority:** Product Owner Confirmed GOV21 & GOV22 in `docs/DECISION_REGISTER.md`  
**Date:** 2026-11-15  
**Baseline Git Head:** `463487c1d5318d14699bb0cc47193de71a6bc0be`  
**Target Branch:** `campaign/p5-progress`  

---

## 1. Goal and Overview

HOMESETS P5 delivers a private, offline-first progress tracking system tailored for calisthenics and resistance band training. It complements the existing workout execution engine (P0–P4) with:
1. **Private Physique Photos:** Front, side, and back angles with private side-by-side comparison. All photo files reside strictly in app-private internal storage; never in public gallery/DCIM/MediaStore.
2. **Body Weight Journaling:** Manual date-tagged kg entries, editing, deletion, and genuine weekly averages (mean of actual measurements only, no fake linear interpolation).
3. **Strength Progress Aggregation:** Automatic progress tracking derived directly from durably completed, non-pain-stopped set logs in SQLite. Tracks best reps per set and estimated volume over time.
4. **Weekly Consistency Visualization:** Displays current rolling 7-day consistency credit count against target workouts/week, preserving approved C3 credit rules.
5. **Daily Meal Checklist:** A simple, nonjudgmental daily checkbox system (3 base meals + up to 2 optional snacks) with inexpensive Egyptian cultural protein suggestions (eggs, cottage cheese / areesh, fava beans / foul, milk, tuna).

---

## 2. Hard Governance & Architectural Invariants

- **Zero New Dependencies (GOV21):**
  - Production runtime: strictly `flutter`, `flutter_localizations`, `intl`, `sqflite`, `path_provider`.
  - Development only (GOV20): `flutter_test`, `flutter_lints`, `sqflite_common_ffi`.
  - Zero charts packages (e.g., `fl_chart`), zero image packages (e.g., `image_picker`), zero permissions packages. Custom charts implemented with standard Flutter `CustomPainter` and `Semantics`.
- **Zero Permissions & Offline Privacy (D02, GOV15, GOV21):**
  - Android release manifest has **0 `<uses-permission>` tags**.
  - No `INTERNET`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, or `CAMERA` broad permissions.
  - `android:allowBackup="false"` and `android:fullBackupContent="false"`.
  - No cloud sync, no remote servers, no analytics, no external tracking.
- **App-Private Storage Lifecycle:**
  - Photo files stored in `<app_docs_dir>/progress_photos/<uuid_or_opaque_id>.jpg`.
  - Deleting a photo record deletes the binary file from disk immediately.
  - Orphaning checks on app launch/migration clean up unreferenced private image files.
- **Physical Device Gate:**
  - Honor X9e Pro / MagicOS 10 physical device testing remains explicitly **UNVERIFIED** (deferred to C9 final acceptance per GOV07).

---

## 3. Database Schema v2 (Additive Migration)

The SQLite database transitions from schema version 1 to 2 via an additive, non-destructive migration. Existing tables (`user_profile`, `equipment_inventory`, `workout_sessions`, `set_logs`, `active_session_state`, `session_salvage_archive`) are 100% preserved.

```sql
-- 1. Weight Entries Table
CREATE TABLE IF NOT EXISTS weight_entries (
  id TEXT PRIMARY KEY,
  weight_kg REAL NOT NULL,
  logged_at TEXT NOT NULL,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_weight_entries_logged_at ON weight_entries (logged_at);

-- 2. Progress Photos Table
CREATE TABLE IF NOT EXISTS progress_photos (
  id TEXT PRIMARY KEY,
  file_path TEXT NOT NULL,
  angle TEXT NOT NULL, -- 'front', 'side', 'back'
  taken_at TEXT NOT NULL,
  notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_progress_photos_taken_at ON progress_photos (taken_at);

-- 3. Daily Meal Checks Table
CREATE TABLE IF NOT EXISTS daily_meal_checks (
  date TEXT NOT NULL, -- YYYY-MM-DD
  meal_slot INTEGER NOT NULL, -- 0 (Breakfast), 1 (Lunch), 2 (Dinner), 3 (Snack 1), 4 (Snack 2)
  is_checked INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (date, meal_slot)
);
```

---

## 4. UI Layout & Navigation Architecture

- **Main Navigation:**
  - `HomesetsApp` maintains a top-level Bottom Navigation Bar with two primary destinations:
    1. **Today (`/today`):** Next scheduled workout, active draft banner, quick consistency summary, Lite mode toggle.
    2. **Progress (`/progress`):** Progress Hub with tabs/sections for Photos, Weight, Strength, Consistency, and Meals.
  - Active Workout Player, Rest Timer, Onboarding/Settings, and Workout Summary remain dedicated full-screen modals.
- **Progress Hub Structure (`ProgressHubScreen`):**
  - Section A: **Weekly Consistency Card** (rolling 7-day credit, status).
  - Section B: **Body Weight Tracker** (current weight, weekly average, interactive CustomPaint line chart, log weight dialog, history list with edit/delete).
  - Section C: **Progress Photos** (Front / Side / Back angle filter, photo thumbnail cards, full-screen view, side-by-side comparison tool, private import).
  - Section D: **Strength Trends** (Exercise selector dropdown from actual logged movements, CustomPaint reps-over-time trend chart, recent set details).
  - Section E: **Daily Meal Checklist** (Today's date, 3 default meal slots + optional slots, quick toggle checkboxes, nonjudgmental Egyptian Arabic guidance).
- **Design System Fidelity:**
  - Hybrid B Kinetic Depth tokens (`#121417` background, `#1A1D24` surface, `#CCFF00` Performance Lime accent, `#FF5E1E` Joint Discomfort Warning).
  - Direction A tabular figures on numeric values, weights, and dates (`HomesetsTypography.tabularBadge`).
  - Egyptian Arabic RTL primary, English LTR fully supported.
  - Responsive at 360×780, 390×844, 412×915 with 1.5× text accessibility.

---

## 5. Work Package Decomposition (WP01–WP12)

1. **WP01:** Baseline verification, acceptance spec, checkpoint & correction matrix.
2. **WP02:** SQLite v1→v2 additive schema migration, domain models, repository CRUD, migration tests.
3. **WP03:** Weight journaling, range validation (30–300 kg), weekly mean calculation, unit tests.
4. **WP04:** Strength trend aggregation from `set_logs`, best reps calculation, filtering, unit tests.
5. **WP05:** Weekly consistency credit visualization, cross-screen parity.
6. **WP06:** Daily meal checklist, date indexing, Egyptian Arabic protein cues, persistence.
7. **WP07:** Android Photo Picker native MethodChannel integration & platform service interface.
8. **WP08:** Private photo sandbox lifecycle, opaque file naming, deletion & orphan cleanup.
9. **WP09:** Progress Hub UI, CustomPaint charts, side-by-side photo comparison, empty states.
10. **WP10:** Responsive layout, 1.5× text scaling, Arabic RTL/English localization, accessibility tests.
11. **WP11:** Android security & privacy audit, backup extraction rules, manifest verification.
12. **WP12:** End-to-end regression, exact-head CI run, correction matrix, draft PR handoff.
