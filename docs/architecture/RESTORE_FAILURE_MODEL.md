# HOMESETS — Failure-Recoverable Restore Design & Crash Consistency Model

**Document Status:** [Active Engineering Architecture]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D02, D18), `docs/PROJECT_RULES.md`  

---

## 1. Addressing Architecture Blocker §5 (TRUTH-04)

Prior drafts asserted that renaming database files provided "guaranteed atomicity across photos and database."
**This claim is technically invalid:**
1. Operating systems do NOT provide atomic multi-file rename operations across different directories.
2. If Android powers down or battery dies while photos are being moved, the filesystem is left in a partial state.
3. SQLite WAL mode maintains active `.db-wal` and `.db-shm` files. Replacing `homesets.db` without properly checkpointing and closing the active database pool corrupts open connections.

**HOMESETS Binding Policy:**
We do not make unsubstantiated "atomicity" claims. Instead, we establish a **Failure-Recoverable Two-Phase Restore State Machine** backed by a cold recovery snapshot.

---

## 2. Restore State Machine & Staged Verification Pipeline

```text
[ Incoming Backup File (.hsbk) ]
               │
               ▼
┌───────────────────────────────────────────────┐
│ Phase 1: Isolated Sandbox Decompression       │
│ - Destination: cacheDir/restore_staging/      │
│ - Zip-Slip path validation                    │
│ - 500 MB expansion bomb ceiling check         │
└──────────────────────┬────────────────────────┘
                       │ Pass
                       ▼
┌───────────────────────────────────────────────┐
│ Phase 2: Offline Preflight Verification       │
│ - Validate SHA-256 for all extracted files    │
│ - Open staged DB in read-only mode            │
│ - Execute: PRAGMA integrity_check;            │
│ - Check schema version compatibility          │
└──────────────────────┬────────────────────────┘
                       │ Pass
                       ▼
┌───────────────────────────────────────────────┐
│ Phase 3: Active Pool Suspension & Checkpoint  │
│ - Close all active SQLite connections         │
│ - Execute: PRAGMA wal_checkpoint(TRUNCATE);   │
│ - Create Cold Recovery Snapshot:              │
│   files/homesets.db -> files/homesets.db.snap │
│   files/physique_photos/ -> .../photos.snap/  │
└──────────────────────┬────────────────────────┘
                       │ Pass
                       ▼
┌───────────────────────────────────────────────┐
│ Phase 4: Atomic Two-Phase Replacement         │
│ - Move staged DB -> files/homesets.db         │
│ - Sync staged photos -> files/physique_photos/│
│ - Reconnect database pool                     │
│ - On success: Delete .snap snapshots          │
│ - On failure: Execute Rollback Matrix         │
└───────────────────────────────────────────────┘
```

---

## 3. Power Loss & Crash Rollback Matrix

| Point of Failure | System State at Crash | Recovery Procedure on Next App Launch |
| :--- | :--- | :--- |
| **Crash during Phase 1 (Decompression)** | Partial files exist in `cacheDir/restore_staging/`. Active database and photos are completely untouched. | Startup routine purges `restore_staging/`. App launches normally into untouched user state. |
| **Crash during Phase 2 (Preflight Verification)** | Staged files extracted, but integrity check interrupted. Live database is completely untouched. | Startup routine purges `restore_staging/`. User alerted that import failed validation. |
| **Crash during Phase 3 (Snapshot Creation)** | `.snap` snapshot may be partially written. Live database connection was closed but live files are unmodified. | Startup routine detects partial `.snap`, deletes `.snap`, reconnects to unmodified live `homesets.db`. |
| **Crash during Phase 4 (Mid-Swap Power Failure)** | Live DB replaced, but photos partially moved. Live state is inconsistent. Snapshot `.snap` is present. | Startup routine detects presence of `.snap` rollback journal: moves `.snap` back to active files, restores 100% pre-restore state, alerts user. |

---

## 4. Verification & Testing Requirements

In Milestone P7, this failure model must be validated through automated test scripts simulating:
1. Truncated database file in archive (`PRAGMA integrity_check` fails $\to$ live DB untouched).
2. Missing photo referenced in manifest (SHA-256 mismatch $\to$ staging rejected).
3. Synthetic crash injection midway through Phase 4 (snapshot rollback restores original state).
