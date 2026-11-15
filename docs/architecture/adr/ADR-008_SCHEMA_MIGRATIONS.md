# ADR-008: Schema Migration Strategy and Crash-Safe Rollback

- **Status:** Recommended (Architecture Baseline)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D02, D18), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

As HOMESETS evolves across milestones P2 through P8, the local SQLite database schema will undergo structural migrations (e.g. adding new tracking columns, indexing frequent queries, adding multi-profile support). Because HOMESETS runs completely offline without remote schema sync, failed migrations can permanently corrupt user workout history.

How should schema versioning and database migrations be structured to prevent data loss and ensure atomic, testable upgrades?

---

## Decision Drivers

1. **Zero Data Loss Invariant:** Upgrades from schema version $N$ to $N+1$ must preserve 100% of existing user workout sessions, personal records, and photos.
2. **Deterministic Step-by-Step Migrations:** Migrations must execute sequentially ($v1 \to v2 \to v3$) rather than jumping across giant ad-hoc scripts.
3. **Automated Migration Testing:** Automated tests must verify migration integrity on realistic historical fixture databases before code merges.
4. **Pre-Migration Safety Snapshot:** A cold snapshot of the SQLite database must be generated prior to executing any DDL alter statement.

---

## Considered Options

- **Option A: Sequential Transactional Migrations + Pre-Upgrade Snapshot (Recommended)**
  - Every schema change is codified in an explicit migration step (`MigrationStep(from: 1, to: 2, action: ...)`).
  - Prior to running DDL, copy `homesets.db` to `homesets.db.pre_migration_vN`.
  - Execute migration inside an atomic SQLite transaction (`BEGIN EXCLUSIVE ... COMMIT`).
  - If migration fails, restore `homesets.db.pre_migration_vN` and alert user.
- **Option B: Destructive Drop-and-Recreate (`onUpgrade: (db) => db.execute('DROP TABLE...')`)**
  - Completely unacceptable for a private fitness app; wipes user history.
- **Option C: Ad-hoc `ALTER TABLE ADD COLUMN` in App Startup**
  - Unversioned, error-prone, untestable across multiple skipped app updates.

---

## Decision Outcome

**Chosen Option:** **Option A: Sequential Transactional Migrations with Pre-Upgrade Snapshot**.

### Invariants:
1. Schema version is stored in SQLite `PRAGMA user_version`.
2. Each migration must be accompanied by an automated roundtrip test (`test/database/migration_test.dart`) reading a historical v1 fixture database and verifying that all records survive into v2 intact.
3. `homesets.db.pre_migration_vN` is preserved until the next successful workout log, guaranteeing rollback safety.
