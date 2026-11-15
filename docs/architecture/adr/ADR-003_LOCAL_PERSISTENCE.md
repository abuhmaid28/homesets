# ADR-003: Android-Only Local Persistence Engine (Drift vs. Raw Sqflite)

- **Status:** Proposed (Technical Analysis Complete; Dependency Gate Pending)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D02, D18), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

HOMESETS is an offline-first private fitness tracker. All user profiles, equipment inventories, workout routines, completed set logs, and historical weight entries must be stored locally in an embedded relational database on the Android filesystem.

Earlier drafts proposed `sqlite3_flutter_libs ^0.5.24` and `drift`. However, upstream maintenance checks reveal:
1. `sqlite3_flutter_libs` is obsolete after `sqlite3` 3.x, as modern Drift packages bundle native SQLite configurations directly.
2. We must determine whether compile-time typed SQL (Drift) justifies its build_runner dependency, or if raw `sqflite` provides a leaner, build-step-free footprint.

---

## Decision Drivers

1. **Schema Migration Safety (D02, D18):** Robust version tracking and migration integrity from v1 to subsequent updates without data loss.
2. **Crash Consistency & Power Loss Resilience:** Resilient handling of WAL and journal modes on Android storage.
3. **Dependency Footprint:** Smallest candidate package set with long-term Android compatibility (Android 12 through Android 16).
4. **Compile-Time Type Safety vs Runtime Simplicity:** Evaluating whether Drift's type-safety outweighs `build_runner` complexity.

---

## Considered Options

- **Option A: Drift Stack (`drift` + `drift_flutter`)**
  - Type-safe Dart queries, compile-time SQL verification, automated schema migration tooling.
  - Requires `drift_dev` and `build_runner` in `dev_dependencies`.
- **Option B: Raw Sqflite (`sqflite`)**
  - Battle-tested standard SQLite plugin for Flutter.
  - Zero code generation required. Queries written in raw SQL strings. Manual schema migration handlers.
- **Option C: Embedded NoSQL (Isar / Hive / ObjectBox)**
  - Fast key-value or document storage. Lacks native relational joins, ACID SQL transactions, and standard SQLite backup tooling.

---

## Decision Outcome

**Recommended Proposal:** **Option A: Drift Stack (`drift: ^2.24.0` + `drift_flutter: ^0.2.0`)** as the primary candidate, with **Option B (`sqflite: ^2.4.1`)** as the zero-codegen fallback.

### Rationale:
Drift provides compile-time query verification and declarative migrations (`MigrationStrategy.onUpgrade`), which prevents runtime column mismatch errors during local schema upgrades. The obsolete `sqlite3_flutter_libs` package is completely omitted, relying directly on `drift_flutter`'s native loader.

### Binding Gate Rule:
No packages will be added to `pubspec.yaml` during Campaign C2. This ADR serves as the technical justification package for Product Owner approval at Gate G6.
