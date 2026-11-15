# HOMESETS — Local Database Logical Schema & Migration Specification

**Document Status:** [Active Engineering Architecture]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D02, D13, D14, D18), `docs/PROJECT_RULES.md`  

---

## 1. Relational Entity Architecture (Version 1 Schema)

HOMESETS uses an embedded relational SQLite database (`homesets.db`) residing in app-private storage. The schema enforces foreign key integrity, cascade rules, and query indexing:

```text
┌─────────────────┐       ┌───────────────────────┐
│  user_profiles  │◄──────┤  equipment_inventory  │
└────────┬────────┘       └───────────────────────┘
         │
         │ 1:N
         ▼
┌─────────────────┐       ┌───────────────────────┐
│scheduled_session├──────►│     exercise_catalog  │
└────────┬────────┘       └───────────┬───────────┘
         │                            │
         │ 1:N                        │ 1:N
         ▼                            ▼
┌─────────────────┐       ┌───────────────────────┐
│    set_logs     ├──────►│      pain_events      │
└─────────────────┘       └───────────────────────┘
         ▲
         │ 1:N
┌────────┴────────┐       ┌───────────────────────┐
│body_weight_logs │       │    physique_photos    │
└─────────────────┘       └───────────────────────┘
```

---

## 2. Complete SQL DDL Specification (v1 Baseline)

```sql
-- Enforce Foreign Key Constraints
PRAGMA foreign_keys = ON;

-- 1. User Profiles
CREATE TABLE IF NOT EXISTS user_profiles (
    id TEXT PRIMARY KEY NOT NULL,
    created_at_utc TEXT NOT NULL,
    updated_at_utc TEXT NOT NULL,
    baseline_age INTEGER NOT NULL,
    baseline_height_cm REAL NOT NULL,
    baseline_weight_kg REAL NOT NULL,
    target_weight_kg REAL NOT NULL,
    wake_time_minutes INTEGER NOT NULL DEFAULT 900, -- 15:00
    shift_start_minutes INTEGER NOT NULL DEFAULT 1140, -- 19:00
    shift_end_minutes INTEGER NOT NULL DEFAULT 240, -- 04:00
    target_workouts_per_week INTEGER NOT NULL DEFAULT 4,
    is_active INTEGER NOT NULL DEFAULT 1
);

-- 2. Equipment Inventory
CREATE TABLE IF NOT EXISTS equipment_inventory (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    has_pull_up_bar INTEGER NOT NULL DEFAULT 1,
    has_door_anchor INTEGER NOT NULL DEFAULT 1,
    has_bands INTEGER NOT NULL DEFAULT 1,
    bands_json TEXT NOT NULL DEFAULT '[]', -- JSON array of calibrated band rungs
    updated_at_utc TEXT NOT NULL
);

-- 3. Exercise Catalog (Bundled immutable library + user custom variations)
CREATE TABLE IF NOT EXISTS exercise_catalog (
    id TEXT PRIMARY KEY NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    name_ar TEXT NOT NULL,
    name_en TEXT NOT NULL,
    movement_pattern TEXT NOT NULL,
    primary_muscles_json TEXT NOT NULL,
    secondary_muscles_json TEXT NOT NULL,
    joint_stress_tags_json TEXT NOT NULL DEFAULT '[]',
    required_equipment_json TEXT NOT NULL DEFAULT '[]',
    supports_band_assistance INTEGER NOT NULL DEFAULT 0,
    supports_band_resistance INTEGER NOT NULL DEFAULT 0,
    unprovocative_alternative_id TEXT,
    is_user_custom INTEGER NOT NULL DEFAULT 0
);

-- 4. Scheduled & Completed Workout Sessions
CREATE TABLE IF NOT EXISTS workout_sessions (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    routine_name_ar TEXT NOT NULL,
    routine_name_en TEXT NOT NULL,
    started_at_utc TEXT NOT NULL,
    ended_at_utc TEXT,
    is_lite_mode INTEGER NOT NULL DEFAULT 0,
    is_completed INTEGER NOT NULL DEFAULT 0,
    is_emergency_stopped INTEGER NOT NULL DEFAULT 0,
    emergency_stop_reason TEXT,
    notes TEXT
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_date 
ON workout_sessions(user_id, started_at_utc);

-- 5. Individual Set Execution Logs
CREATE TABLE IF NOT EXISTS set_logs (
    id TEXT PRIMARY KEY NOT NULL,
    session_id TEXT NOT NULL REFERENCES workout_sessions(id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES exercise_catalog(id),
    set_index INTEGER NOT NULL,
    target_min_reps INTEGER NOT NULL,
    target_max_reps INTEGER NOT NULL,
    performed_reps INTEGER NOT NULL,
    band_identifier TEXT,
    band_application_mode TEXT, -- 'ASSISTANCE' or 'RESISTANCE'
    exertion_rating TEXT NOT NULL, -- 'EASY_RESERVE', 'TARGET_SWEETSPOT', 'MAX_EFFORT', 'PAIN_STOPPED'
    is_pain_stopped INTEGER NOT NULL DEFAULT 0,
    completed_at_utc TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_set_logs_session_ex 
ON set_logs(session_id, exercise_id);

-- 6. Joint Pain Incident Events (Safety Audit Trail)
CREATE TABLE IF NOT EXISTS pain_events (
    id TEXT PRIMARY KEY NOT NULL,
    set_log_id TEXT REFERENCES set_logs(id) ON DELETE SET NULL,
    exercise_id TEXT NOT NULL REFERENCES exercise_catalog(id),
    joint_tag TEXT NOT NULL, -- e.g. 'SHOULDER_SUBACROMIAL'
    pain_severity INTEGER NOT NULL, -- 1 to 5 scale
    notes TEXT,
    occurred_at_utc TEXT NOT NULL,
    is_resolved INTEGER NOT NULL DEFAULT 0
);

-- 7. Body Weight Tracking (Weekly Rolling Averages)
CREATE TABLE IF NOT EXISTS body_weight_logs (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    weight_kg REAL NOT NULL,
    logged_date TEXT NOT NULL, -- YYYY-MM-DD
    created_at_utc TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_weight_user_day 
ON body_weight_logs(user_id, logged_date);

-- 8. Sandboxed Physique Photos Metadata
CREATE TABLE IF NOT EXISTS physique_photos (
    id TEXT PRIMARY KEY NOT NULL,
    user_id TEXT NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    relative_file_path TEXT NOT NULL, -- relative to app_private_photos/
    captured_at_utc TEXT NOT NULL,
    pose_type TEXT NOT NULL, -- 'FRONT', 'SIDE', 'BACK'
    sha256_checksum TEXT NOT NULL,
    is_quarantined INTEGER NOT NULL DEFAULT 0
);
```

---

## 3. Write-Order Invariants & Crash Recovery

To handle sudden OS kills (e.g. battery death during workout):
1. **Immediate Write-Order Invariant:** Every set is persisted to `set_logs` the exact millisecond the user taps `تسجيل المجموعة`. Set logs are never buffered in volatile RAM alone.
2. **Crash Recovery Detection:** Upon app launch, the app queries:
   ```sql
   SELECT id, routine_name_ar, started_at_utc 
   FROM workout_sessions 
   WHERE is_completed = 0 AND is_emergency_stopped = 0;
   ```
   If an open session exists:
   - If `started_at_utc` was within the last 3 hours: Display the Crash Recovery Banner (`design/ux/edge_states_wireframe.html`) allowing the user to resume set $N+1$.
   - If older than 3 hours: Automatically mark `is_completed = 1` with a `phone_killed_timeout` note, preserving all recorded sets.
