# HOMESETS — Accurate Consolidated Product Owner Gate (C2-R + C3)

**Status: [OPEN — Awaiting Ahmed's explicit approval].**
**Date:** 2026-11-15.
**Supersedes:** the earlier C2R owner package at this path which incorrectly described C1 Direction A as orange and Direction B as amber/teal, and falsely implied OS backup/restore rules were already deployed. No production app or Android Manifest exists yet.
**Source:** [C1 A/B side-by-side](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/docs/reviews/C1V2_VISUAL_DIFF_AND_DECISION.md), [C2-R external review](https://github.com/abuhmaid28/homesets/blob/main/docs/reviews/C2R_EXTERNAL_FLUTTER_READINESS_2026-11-15.md).
**Current status:** Draft PR #5 and #9 are unmerged; real foundation-only CI green at `93f15ee9209ca2154c751e49c3cb185603f3d066`; not Flutter CI.

## Decision 1 — Visual direction, not fake alternate colors
**[Recommended] Hybrid B + A precision**
- Take **Direction B — Kinetic Depth** as the primary look: dark warm charcoal (`#121316`), Performance Lime (`#CCFF00`), rounded and tactile surfaces.
- Borrow **Direction A — Performance Stealth** tabular-numeral style and clear high-contrast set/rest timers.
- Use Arabic Egyptian copy, AR/EN RTL/LTR, accessible contrast/touch sizes, tasteful subtle glow (not excessive), no debug labels or placeholder logos presented as final.
- Owner-preferred Pull-Up Motion logo PNG is **still missing from GitHub**; use neutral HOMESETS wordmark temporarily, no final adaptive launcher icon until exact PNG+vector/icon checks.
- Actual comparison: [A Today](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_a_today_390x844.png), [B Today](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_b_today_390x844.png), [B Workout](https://github.com/abuhmaid28/homesets/blob/campaign/c1-design-foundation/design/reviews/c1-v2/screenshots/dir_b_workout_390x844.png).

## Decision 2 — Equipment and workout safety (conservative)
**[Recommended]**
- Default owned equipment: doorway pull-up bar and resistance bands, plus no-special-equipment bodyweight movements. No added weights, loaded backpack or assumed gym equipment.
- An **overhead/door-anchor pulldown is unavailable unless a verified suitable anchor is explicitly enabled**, not merely because bands exist. Table inverted rows default disabled until stable load-bearing furniture is verified; neutral-grip handles never assumed on a straight pull-up bar.
- Pain during exercise => immediate STOP and preserve logged sets; **no automatically prescribed loaded substitute**, no diagnosis or shame. A user can mark avoid areas.
- Proposed gradual deload on return after extended absence is an adjustable conservative heuristic, not an independently validated medical percentage. No promise that 15m Lite is always achieved; estimates vary with rest and form.
- This is a software safety design guardrail, not medical advice or qualified exercise-science certification.

## Decision 3 — Offline data and privacy model
**[Recommended]**
- Local-only app-private SQLite data and private physique photos once P5 implemented. No accounts/backend/cloud sync/runtime AI/telemetry.
- Explicit Android backup/data extraction configurations in implementation, **not deployed yet**, with OS/OEM differences treated as unverified until final Honor acceptance.
- Manual explicit backup/export with clear warning that a copied archive can be shared to outside apps; no automatic cloud upload. Staging, validation and rollback planned; **not guaranteed atomic/data-loss-proof** until crash/fault-injection tests and final device acceptance.
- P0–P4 C3 scope includes profile/session/set persistence **only**. Photos/backup implementation belongs later P5/P6.

## Decision 4 — Minimal dependency policy
**[Recommended] Conditional allowlist; versions must be checked/locked in the coding campaign.**
- Prefer typed **Drift + drift_flutter** *if* the actual selected compatible versions can be resolved, analyzed and built with existing Flutter/Dart/Android tools; otherwise use **sqflite** as a reviewed fallback, not both.
- Other category-scoped approved candidates when needed: `path_provider`, Flutter SDK localization/`intl`, `archive`, `crypto`, `flutter_local_notifications`; only for their corresponding milestone, not all on P0. `uuid` optional and may be replaced with simple local IDs if justified. No opaque plugins or paid service.
- Reference *current as-of-2026-11-15* public candidates: `drift 2.35.4`, `drift_flutter 0.3.1`, `sqflite 2.4.6`, `flutter_local_notifications 23.0.2`. These are **not yet proven build-compatible or installed**; validate license/min SDK/Android config and `flutter pub get`, analyze/test/APK build. Do not silently use stale `^2.24.0` or `^18.0.1` as current.
- No other dependency without new owner authorization; pin/review `pubspec.lock`.

## Decision 5 — First real Flutter implementation campaign
**[Recommended] Authorize [C3-MEGA Issue #11](https://github.com/abuhmaid28/homesets/issues/11): P0–P4 Android Flutter core, 32 substantive Work Packages**, after explicit grouped approval of decisions 1–4.
- Real code: safe Flutter scaffold, true Flutter CI, AR/EN RTL hybrid design, pure-Dart engine, capability filtering, local sessions and migrations, onboarding, Today, Active Set/Rest, Lite and Summary.
- Need actual `flutter analyze`, `flutter test`, `flutter build apk`, exact-head CI and true logs, plus critical safety regression. Do not claim execution of all 106 scenarios until code really runs them.
- Within approved scope, Antigravity can continuously modify/test/commit/create PR and guarded-merge after actual exact-head checks pass. No phone checks until final release (GOV07); no automatic destructive/force-push actions. Keep checkpoints for resumption if session ends.
- **Out of C3:** P5 progress photos/weight graphs and P6 notification/backup implementations, final signing/private release and final Honor acceptance.

## Approval wording (one grouped choice)
> I approve HOMESETS C3-MEGA implementation with Hybrid B (Kinetic Depth charcoal/lime + tabular timers), bar+bands only and verified-anchor/furniture default exclusions, stop-first/no diagnosis and non-medical adjustable deload, offline app-private storage/manual-only backup proposal, and the constrained minimal dependency allowlist with version/build/license verification. I authorize the 32-work-package real Flutter P0–P4 campaign with automated tests and guarded merges. No new feature scope, unknown plugins or destructive operations.

**No decision is recorded as confirmed until Ahmed actually gives this approval.** If he prefers A/B or different storage/deps, update this package before C3 starts.
