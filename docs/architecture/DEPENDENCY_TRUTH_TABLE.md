# HOMESETS — Dependency, License & SDK Version Truth Table

**Document Status:** [Active Technical Truth Table]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Policy Status:** **CANDIDATES ONLY — NO PACKAGES INSTALLED IN PUBSPEC.YAML**  

---

## 1. Executive Dependency Governance

In strict accordance with `PROJECT_RULES.md` and `DECISION_REGISTER.md` (GOV05, O10):
- **Zero dependencies** are added to `pubspec.yaml` in Campaign C2.
- Every candidate package is audited against official pub.dev repositories, licensing constraints, minimum SDK versions, and Android 12–16 runtime compatibility.
- Upstream deprecations (e.g., `sqlite3_flutter_libs`) are actively excised.

---

## 2. Authoritative Candidate Truth Table

| Package Name | Official pub.dev URL | Candidate Version | License | Min Dart / Flutter | Android / SDK Requirements | Deprecation Status & Technical Assessment |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `drift` | https://pub.dev/packages/drift | `^2.24.0` | MIT | Dart $\ge 3.5.0$<br>Flutter $\ge 3.24.0$ | Android compileSdk 34+ | **Active / Stable.** Primary relational ORM with compile-time type safety. Zero network usage. |
| `drift_flutter` | https://pub.dev/packages/drift_flutter | `^0.2.0` | MIT | Dart $\ge 3.5.0$<br>Flutter $\ge 3.24.0$ | Android NDK / embedder | **Active / Preferred.** Replaces deprecated manual setup. Bundles modern native SQLite bindings without requiring obsolete helper packages. |
| `sqlite3_flutter_libs` | https://pub.dev/packages/sqlite3_flutter_libs | *REJECTED* | MIT | Dart $\ge 3.0.0$ | Legacy Android ABIs | **OBSOLETE.** Upstream author explicitly documents that `sqlite3_flutter_libs` is obsolete after `sqlite3` 3.x and superseded by `drift_flutter`. **Omitted from proposal.** |
| `sqflite` | https://pub.dev/packages/sqflite | `^2.4.1` *(Fallback)* | BSD-2-Clause | Dart $\ge 3.5.0$<br>Flutter $\ge 3.24.0$ | Android API 16+ | **Active / Stable Fallback.** Zero-codegen raw SQLite alternative if compile-time build_runner is rejected. |
| `path_provider` | https://pub.dev/packages/path_provider | `^2.1.5` | BSD-3-Clause | Dart $\ge 3.3.0$<br>Flutter $\ge 3.19.0$ | Android Scoped Storage | **Active / Standard.** Official Flutter team plugin to resolve `getApplicationDocumentsDirectory()` and `getTemporaryDirectory()`. |
| `flutter_localizations` | *(Flutter SDK internal)* | *(Bundled)* | BSD-3-Clause | Pinned to Flutter | Android LocaleManager | **SDK Core.** Built into Flutter SDK. Zero external package dependency. Powers native Arabic RTL and English LTR. |
| `intl` | https://pub.dev/packages/intl | `^0.20.1` | BSD-3-Clause | Dart $\ge 3.3.0$ | Pure Dart | **Active / Standard.** Official Dart formatting utility for dates, times, and BiDi numbers. |
| `uuid` | https://pub.dev/packages/uuid | `^4.5.1` | MIT | Dart $\ge 3.0.0$ | Pure Dart | **Active / Stable.** Used strictly for SQLite row persistence UUIDs (RFC 4122 v4). Prohibited inside pure domain plan engine calculations. |
| `crypto` | https://pub.dev/packages/crypto | `^3.0.6` | BSD-3-Clause | Dart $\ge 3.4.0$ | Pure Dart | **Active / Standard.** Pure-Dart implementation of SHA-256 for backup manifest validation and tamper detection. |
| `archive` | https://pub.dev/packages/archive | `^3.6.1` | Apache-2.0 | Dart $\ge 3.0.0$ | Pure Dart | **Active / Standard.** Offline ZIP compression and extraction for local backup export/import. Tested against Zip-Slip path traversal. |
| `flutter_local_notifications` | https://pub.dev/packages/flutter_local_notifications | `^18.0.1` | BSD-3-Clause | Dart $\ge 3.5.0$<br>Flutter $\ge 3.24.0$ | Android API 21+<br>POST_NOTIFICATIONS (API 33+) | **Active / Evaluated.** Candidate for optional 3:30 PM reminder. Behavior on Honor MagicOS 10 remains UNVERIFIED until physical acceptance. |

---

## 3. License & Cost Verification

- **Zero Paid Dependencies:** All candidates are open-source with permissive, royalty-free licenses (MIT, BSD-2-Clause, BSD-3-Clause, Apache-2.0).
- **Zero Cloud / Telemetry:** None of the candidate packages bundle background analytics, telemetry, or remote API endpoints.
- **Copyleft Audit:** Zero GPL, AGPL, or restrictive copyleft libraries are included.
