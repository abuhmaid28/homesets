# HOMESETS — C2-R External Review and Flutter Readiness Gate

**Review date:** 2026-11-15
**Reviewer:** ChatGPT, independent GitHub inspection
**PR:** [#9](https://github.com/abuhmaid28/homesets/pull/9) (Draft / not merged)
**Verified GitHub head:** `93f15ee9209ca2154c751e49c3cb185603f3d066`. The pasted Antigravity report gave a different full SHA (`93f15ee285...`), so GitHub is canonical.
**Exact-head GitHub Actions:** [Run #43662773807](https://github.com/abuhmaid28/homesets/actions/runs/43662773807), pull_request, **SUCCESS**. This verifies **Foundation** docs/fixtures/validator tests, NOT real Dart engine, Flutter UI, APK or Honor device.

## Verified accomplishments
- C2-R commits reached PR #9, 47 changed paths across C2-MEGA/C2-R.
- 106 scenario fixtures and 14 exercise catalog records: no identical input/output scenario vector pairs, and named exercise references resolve.
- `validate_fixtures.py` strengthened for type/category/action/reference checks; `tools/quality/tests/test_validation.py` includes 21 test functions. This tests **validation tooling**, not actual exercise prescriptions.
- Real remote workflow run green on the exact head SHA. No inferred success from agent log.

## Unresolved architecture and owner-gate blockers (do not silently auto-approve)

**C2R-X01: Unsafe exercise eligibility semantics — HIGH.**
- `pulldown_door_band` says `required_equipment=["resistance_bands"]`, `optional_accessories=["door_anchor"]`, but technique itself **requires** verified overhead anchor. Engine filtering on required equipment could select it with bands only; default exclude without an actual validated anchor point. Add explicit exercise eligibility predicate and negative case.
- `row_table_inverted` requires stable bodyweight-supporting furniture, but its required equipment says only `bodyweight`. Default exclude without verified furniture safety.
- `chinup_neutral` combines neutral and underhand grips; don't assume a straight-bar user has parallel-grip handles.
- Validate mandatory capability constraints **in code and tests**, not just prose. The existing fixture validator does not enforce optional accessories or verified anchor/furniture.

**C2R-X02: Product Owner visual decision package factually wrong — HIGH.**
- `docs/reviews/C2R_OWNER_GATE_PACKAGE.md` describes Direction A as *orange* and Direction B as *amber/teal*. Actual C1 Draft PR #5 [A/B Visual Decision Sheet](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/docs/reviews/C1V2_VISUAL_DIFF_AND_DECISION.md) says both are **charcoal + Performance Lime**.
- Correct alternatives: **A Performance Stealth**, **B Kinetic Depth**, **Hybrid B raised/rounded surfaces plus A tabular numerals**, all with current owner-preferred Pull-Up Motion icon **not final**. No fabricated visual options.

**C2R-X03: Source-of-truth and implementation status overclaims — MEDIUM/HIGH.**
- Owner package calls `dataExtractionRules` 'deployed', photo privacy absolute and restore pipeline 'eliminates corruption' though no Flutter/Android app or actual restore implementation exists. Change to **proposed design, OS/OEM/device behavior unverified**.
- Training pain STOP is a useful conservative UX invariant, but named joint diagnoses and automatically 'safe' alternatives cannot be guaranteed; deload 30–40% after 14 days is a heuristic requiring validation and adjustment. App is not medical advice.

**C2R-X04: Dependency/version claims outdated or untested — HIGH.**
- As of 2026-11-15 official pub.dev has **drift 2.35.4**, **drift_flutter 0.3.1**, **flutter_local_notifications 23.0.2**, and **sqflite 2.4.6**. The current draft uses much older candidates `drift ^2.24.0`, `drift_flutter ^0.2.0`, `flutter_local_notifications ^18.0.1`, with unsupported “100% Android 16 compatibility”/APK overhead/build-time estimates. See [drift](https://pub.dev/packages/drift/versions), [drift_flutter](https://pub.dev/packages/drift_flutter/versions), [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications/versions), [sqflite](https://pub.dev/packages/sqflite/versions).
- No new dependency until Product Owner authorizes **an allowlist** and the agent validates exact compatibility via actual `flutter pub get`, analyze/tests/build in a scoped implementation campaign. Stale broad `^...` candidates cannot be automatically treated as approved.

## Proposed consolidated Product Owner decision, not yet taken
- **Visual:** Hybrid B (Kinetic Depth charcoal×lime/rounded tactile controls) + A tabular timers/counters; remove technical headers/diagnostic overlays from customer-facing UI; exact owner-selected logo reference pending.
- **Hardware/safety:** Confirm bar+bands+bodyweight only. No door-anchor exercise or furniture bodyweight load until owner specifically declares verified anchor/furniture; pain STOP first, no automatic loaded substitution; deload as adjustable conservative *proposed* heuristic.
- **Data:** app-private offline files/DB/photos with no intentional cloud sync; Android backup policies best effort and manual-only export/restore with explicit sharing warning and failure-injection tests before acceptance, never absolute guarantees.
- **Architecture:** Pure-Dart deterministic engine. Prefer modular local storage; choose minimal dependency footprint, validate versions before any install. Bootstrap Flutter with SDK-only packages if relevant decision remains open.
- **Next:** authorize a large **real Flutter C3** campaign after one grouped decision. It must produce actual code, analyze/test/build and exact-head Flutter CI, unlike earlier documentation-only phases.

## Next action
Present **one grouped Product Owner approval**, correct invalid owner-decision document on Draft PR #9 or propose a correction; leave both Draft PRs unmerged until the owner gate. Then launch C3 implementation campaign **only after explicit approval**. Avoid yet another mega documentation loop.

**Review status:** C2-R scoped delivery and Foundation CI evidence **verified**; implementation, brand, dependency, safety, photo privacy, APK and Honor acceptance **not verified/approved**.
