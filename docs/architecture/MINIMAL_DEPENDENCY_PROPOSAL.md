# HOMESETS — Minimal Dependency Options & Lean Stack Proposal

**Document Status:** [Proposed Options for Product Owner Gate G6 Review]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D02, GOV05, O10), `docs/PROJECT_RULES.md`  

---

## 1. Executive Proposal Summary

To honor Product Rule §Scope ("no dependencies without approval") and Decision D02 ("zero recurring cost, offline-first"), this document establishes two lean dependency architectures for Product Owner review:

- **Option A (Typed Compile-Time Stack):** Uses `drift` and `drift_flutter` for compile-time verified SQL queries and declarative migrations.
- **Option B (Zero-Codegen Raw Stack):** Uses `sqflite` for a featherweight, zero-code-generation footprint.

Both options strictly disallow obsolete packages (`sqlite3_flutter_libs`) and enforce zero network/telemetry libraries. **Neither option is installed into `pubspec.yaml` during this campaign.**

---

## 2. Comparative Dependency Stacks

### Stack Option A: Modern Typed Drift Architecture (Recommended)

```yaml
# Prospective dependencies for Milestone P2+ (DO NOT INSTALL YET)
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # Persistence & File Storage
  drift: ^2.24.0
  drift_flutter: ^0.2.0
  path_provider: ^2.1.5

  # Localization & Utilities
  intl: ^0.20.1
  uuid: ^4.5.1
  crypto: ^3.0.6
  archive: ^3.6.1

  # Optional Background Reminders
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.24.0
  build_runner: ^2.4.13
```

- **Runtime External Package Count:** 7 packages (excluding Flutter SDK internals).
- **Key Advantage:** Drift verifies SQL column types, foreign keys, and queries at compile-time. Schema migrations are type-safe and verifiable via automated tests before deployment.
- **Tradeoff:** Requires running `dart run build_runner build` during development when modifying database entity schemas.

---

### Stack Option B: Zero-Codegen Raw SQLite Architecture (Ultra-Lean Fallback)

```yaml
# Prospective dependencies for Milestone P2+ (DO NOT INSTALL YET)
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # Persistence & File Storage
  sqflite: ^2.4.1
  path_provider: ^2.1.5

  # Localization & Utilities
  intl: ^0.20.1
  uuid: ^4.5.1
  crypto: ^3.0.6
  archive: ^3.6.1

  # Optional Background Reminders
  flutter_local_notifications: ^18.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
```

- **Runtime External Package Count:** 6 packages.
- **Key Advantage:** Zero code-generation build step (`build_runner` completely eliminated). Fastest possible development build times.
- **Tradeoff:** Queries are written in raw SQL strings (`db.rawQuery('SELECT ...')`). Schema migrations must be managed with custom handwritten SQL scripts without compile-time column validation.

---

## 3. Detailed Tradeoff & Evaluation Matrix

| Technical Criterion | Option A: Drift Typed Stack | Option B: Raw Sqflite Stack | Assessment for HOMESETS |
| :--- | :--- | :--- | :--- |
| **SQL Type Safety** | **Compile-Time Checked:** Typo in column name breaks build before running. | **Runtime Checked:** SQL typos crash at runtime. | Option A provides superior protection against data corruption in private fitness tracking. |
| **Schema Migration Safety** | Declarative migration steps with step-by-step schema verification. | Manual `db.execute('ALTER TABLE ...')` strings in `onUpgrade`. | Option A minimizes risk of corrupting user history across app upgrades. |
| **Build Velocity & Tooling** | Requires `build_runner` (~10s code generation on schema change). | **Instant:** Zero code generation step. | Option B is faster during initial scaffolding; Option A is safer for long-term data stability. |
| **Estimated APK Size Overhead** | $\approx +1.8$ MB (compiled Drift classes). | $\approx +1.2$ MB (standard JNI wrapper). | Negligible difference ($<1$ MB difference). |
| **Android 12–16 Compatibility** | 100% verified via native embedder in `drift_flutter`. | 100% verified via native Android SQLite bindings. | Tied. Both support Scoped Storage and Android 16. |
| **Offline Autonomy & Cost** | Zero network calls, zero recurring cost. | Zero network calls, zero recurring cost. | Tied. 100% offline. |

---

## 4. Recommendation for Product Owner Review

- **Primary Recommendation:** **Option A (Drift Typed Stack)**. Because HOMESETS handles personal physique photos, progressive overload calculations, and long-term historical workout data with zero cloud backup, compile-time SQL verification and declarative migrations are critical to preventing silent data corruption.
- **Fallback Threshold:** If Ahmed prefers zero build-step tooling, Option B (Sqflite) can be substituted immediately without altering the underlying pure-Dart domain plan engine.
