# ADR-007: Backup Archive Format, Integrity Verification, and Staged Restore

- **Status:** Recommended (Architecture Baseline)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D02, D18), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

Because HOMESETS has zero cloud infrastructure, user workout logs, personal records, and private physique photos must be backed up manually by the user (D02, D18). 

Earlier drafts claimed that renaming database files "guaranteed atomicity across photos and database." As highlighted in Issue #8, this claim is unjustified: sudden power failure, partial file extraction, SQLite WAL/SHM file locks, or malicious Zip-Slip attacks can corrupt active user data.

How should local backup and restore be architected to guarantee tamper detection, zip-slip defense, crash consistency, and failure recovery?

---

## Decision Drivers

1. **Failure-Recoverable Restore:** Active database and photos must remain 100% intact if a restore archive is corrupt or interrupted midway.
2. **Zip-Slip & Path Traversal Immunity:** Malicious or malformed archives must never write files outside the temporary staging sandbox.
3. **Offline Checksum Validation:** Manifest SHA-256 validation before touching live application data.
4. **Transparent User Control:** Backups are user-initiated exports (`.hsbk` / `.zip`), stored wherever the user chooses (device downloads, USB, or local private storage).

---

## Considered Options

- **Option A: Staged Two-Phase Extraction with Rollback Journal (Recommended)**
  - Backups packaged as a versioned ZIP containing `manifest.json`, `homesets_export.db`, and `photos/`.
  - Restore extracts to `cacheDir/staging/`.
  - Preflight validates:
    1. Canonical path check (disallow `../` or absolute paths).
    2. Total uncompressed size cap (expansion bomb defense $\le 500$MB).
    3. SHA-256 checksum match.
    4. SQLite `PRAGMA integrity_check` on staged DB.
  - Two-Phase Swap: Active DB closed, moved to `.backup_snapshot`, staged DB moved in, photos synced.
  - On failure at any step: rollback to `.backup_snapshot`.
- **Option B: Direct In-Place Overwrite**
  - Unzips archive directly into app documents directory.
  - Fatal defect: Corrupt archive leaves the app in an unbootable, half-overwritten state with irrecoverable data loss.
- **Option C: Custom Binary Serialization**
  - Custom binary format. Difficult to inspect, verify, or migrate across schema versions.

---

## Decision Outcome

**Chosen Option:** **Option A: Staged Two-Phase Extraction with Rollback Journal**.

### Safety Invariants:
1. Active database is never closed or modified until staged verification completely passes.
2. Zip extraction strictly validates `File(entry.name).canonicalPath.startsWith(stagingDir.canonicalPath)`.
3. Total photos count and individual file checksums are recorded in `manifest.json`.
4. WAL checkpoint (`PRAGMA wal_checkpoint(TRUNCATE)`) is enforced before backup export.
