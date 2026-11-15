# HOMESETS — Roadmap and Automated Acceptance Gates

**Status:** Active workflow approved 2026-11-14. Individual product, brand and architecture designs still require their documented approval gates. Read `docs/AGENT_AUTONOMY_POLICY.md` and GOV06–GOV11 before executing.
**Explicit amendment:** the old rule that each P0–P8 milestone must be run on the real phone before the next is superseded. Automated evidence + exact-head CI are required during development; one integrated human Honor test occurs at final acceptance.

## Planning gates — no accidental product scope expansion

| Gate | Goal and scope | Completion criteria |
| --- | --- | --- |
| G0 — Governance & isolation | Private repo, source of truth, work rules, local clone, approved autonomous merge rules, source logo preservation | Git remote/workspace verified, rules actually discovered, reference PNG committed and SHA checked, no unrelated files modified |
| G1 — Product Blueprint | Freeze a realistic 15–30 min, offline, bands/bar muscle-building MVP and safety/problem journeys | Owner has seen/approved proposed scope and acceptance; ambiguities recorded |
| G2 — Brand | Validate HOMESETS candidate, owner-preferred Pull-Up Motion, icon, wordmark, font/license and color system | Actual vector/size/mono/adaptive-icon evidence; explicit owner design approval |
| G3 — UX | Onboarding, Today, Workout, Lite, swap, recovery, Progress and settings journeys | Flows and wireframes presented for owner review; pain and interrupted states covered |
| G4 — Design System | Dark/light roles, tokens, AR/EN RTL, accessibility, components | Design spec, contrast samples, states and reusable components reviewed |
| G5 — High-fidelity design | Today, workout, progress and representative onboarding mockups | Owner approves selected visual direction before implementation |
| G6 — Architecture & safe plan logic | Pure-Dart plan engine, local schema/backups/photo privacy, test strategy, package/license selection | Owner reviews major technical/safety choices; no unapproved dependency |
| G7 — Antigravity rules + CI | Verify local connection, real rule discovery, repeatable automated analysis/test/build on PR head | Evidence-backed workspace scope; CI running green against a known exact head; controls documented |

Each approved planning campaign may draft and revise multiple files continuously without routine user approval. **Owner approval remains necessary for final brand/product/safety choices, not every implementation step.**

## Runtime milestones P0–P8 — agent-driven, human device check deferred

| Milestone | Goal | Automated evidence required before integration |
| --- | --- | --- |
| P0 — Android scaffold | Minimal offline Android-only Flutter app, documented repo structure | `flutter analyze`, `flutter test`, `flutter build apk --debug`, CI on exact head, APK file/log produced; **no Honor run required yet** |
| P1 — Foundations | Design tokens, theme gallery, navigation, gen-l10n AR/EN RTL | Widget tests for core components, themes, RTL, accessibility + analyze/build/CI |
| P2 — Data | Versioned local schema, migration tests, validated bundled exercise catalog | Migration/JSON integrity and restart persistence tests, analyze/build/CI |
| P3 — Plan engine | Deterministic progression, recoveries, substitutions and Lite mode | Thorough pure Dart tests for equipment/pain exclusion, overload, missed days and safe limits; sample plans reviewed for logic |
| P4 — Core loop | Onboarding, Today, Workout player and pause/resume | Widget/state restoration tests, end-to-end simulation where feasible, analyze/build/CI |
| P5 — Progress | Photo/weight/strength/consistency + meal checklist | Privacy/file-storage checks, trend math/DB tests, photo lifecycle, backup compatibility where relevant |
| P6 — Reminders/Backup | Local notification scheduling, validated export/import | Permission-path tests, export/import round trip with photos and corruption cases, static checks and build |
| P7 — Polish/release candidate | Accessibility, performance, signing plan, failure recovery | Release build logs, app permissions/a11y/privacy checks, regression suite, installation/update plan; keep device behavior unverified |
| P8 — Private sharing documentation | Install guide and supported equipment choices, no new fitness goal without authorization | Documentation checks, build artifacts, license inventory; unresolved friend-goal scope noted |

**Required for every implementation merge:** authorized scope, reviewed diff, actual logs, artifact/test evidence, **green exact-head CI**, no skipped/missing required check, no critical defects, valid dependency/license decisions, correct target. No merge if CI is absent or fails. Underlying GitHub platform Auto-merge is optional; ordinary merges may be automated by Antigravity if the gates genuinely pass.

## Final integrated human acceptance (single phone-testing phase)
Install APK wirelessly on Honor X9e Pro; complete real 15–30 minute workout and Lite, interruptions and app restart, missed days, RTL, photo privacy, weight/strength trends, reminders/permission limits, offline mode, backup/restore, signing and upgrade with data intact. Any failure reopens implementation for another automated cycle and final retest. **No release is final until this gate passes.**

## MVP wall — unchanged
In: goal/equipment/session-time setup; Today; Lite; one-handed sets/rest logging; safe plan engine; private photos, trends, weekly consistency; meal checklist; settings/manual backup; optional local reminders; Arabic RTL + English; Android offline APK.
Out: accounts, cloud/backend, online AI, billing, calories/macros, wearables, social, Play Store, iOS, paid services, new training goals without separate scope approval.

## Evidence and governance
Each campaign: clear goal, exact file areas, exclusions, preapproved dependencies, acceptance tests, stop conditions, branch/PR strategy and rollback. Internal small commits with raw `flutter analyze`, `flutter test` and build output where relevant. The agent continues autonomously after green checks, not after guessed success. No force pushes/destructive actions. ChatGPT independently reviews supplied evidence; agent self-reports are not proofs.

**Open design conflict:** Original Master §5 says build-muscle goal only, while P8 mentions a friend selecting a different goal. More goals remain post-MVP until Ahmed changes scope.

## 2026-11-15 — approved transition to real implementation (no new MVP scope)
**Owner-approved gate:** GOV12–GOV19. C1 selected **Hybrid Direction B Kinetic Depth + A tabular timers** for P0–P4. C2 architecture policy approved with conservative equipment/pain guards and conditional minimum dependencies. P0–P4 implementation can start under [C3-MEGA Issue #11](https://github.com/abuhmaid28/homesets/issues/11) **without more routine approval**; use approved source as reference, not automatic wholesale acceptance of prior draft PRs.
- First produce actual Flutter scaffold & **Flutter CI**; then widgets/AR-EN RTL, deterministic safe workout engine, local persistence and workout journey, backed by real tests/build/APK logs; incremental commits and guarded PR merges.
- **Package gate:** Direct packages limited to GOV16 allowlist and installed only where P0–P4 requires. Actual license/SDK resolution/Gradle and offline checks mandatory. No unrelated package.
- **Phone gate:** no device testing between P0–P4, one final physical Honor acceptance per GOV07; do not claim runtime device verification.
- Remaining unapproved: exact original logo binary/launcher vector, P5–P8 details/extra dependencies, final signed package ID/release.
