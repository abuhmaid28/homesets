# HOMESETS — End-to-End Master Execution Plan

**Prepared:** 2026-11-14 | **Status:** [Recommended] Campaign delivery mapping; references approved *process* GOV06–GOV11. New product/design specifics require Product Owner gate approval.
**Repo:** `abuhmaid28/homesets` (private) | **Platforms:** Android only, Flutter, offline-first, zero recurring cost | **Owner:** Ahmed (product decisions only).
Canonical: [Decision Register](DECISION_REGISTER.md), [Agent Autonomy Policy](AGENT_AUTONOMY_POLICY.md), [Roadmap](ROADMAP.md), [Status](PROJECT_STATUS.md), [Original Brief](MASTER_PROJECT_INITIALIZATION_PROMPT.txt).

## Mission & value
One-tap clarity about the workout to do at home using bar and bands, easy one-handed set/rest logging in 15–30 min, safe progression/recovery, private progress photos/weight/strength and gentle weekly consistency. Egyptian Arabic RTL first with English option. No backend, AI runtime, accounts, data sales, Play Store or paid services.

## Work mode
- Every **campaign** is a substantive end-to-end delegation; split work internally into tiny, independently testable slices with checkpoints, self-reviews, actual logs, commits and issue status.
- The agent continues without routine questions while inside the explicit authorized campaign scope. Once blocked, records evidence and exits safely; it does not invent results or expand scope.
- Existing [Confirmed] product decisions always prevail. Process supersession: **human** phone testing only at final release, but automated tests/CI for all code milestones. Guarded automatic implementation PR merges only after **real exact-head green CI**, valid dependencies/scope, necessary major gate approval, and no critical findings.
- Product Owner reviews **grouped visual and safety/architecture decision packages**, not Git commands, individual buttons, or minor code decisions.
- The agent cannot be promised an exact number of hours: quotas, workspace interruptions and blockers are external. Never pad tasks just to consume time.
- Work must stay in `homesets`; no destructive actions, force pushes, secret leakage, paid/cloud services, unrelated projects or unapproved dependencies.
- All campaigns must preserve local output/commits for continuation if Antigravity session stops.

## Campaign sequencing with concrete acceptance gates

| Campaign | Goal and deliverables | Automation scope and verifiable exit | Owner gate |
| --- | --- | --- | --- |
| C0 — Foundation | Private repo, source of truth, linked local workspace, agent rules; logo reference asset tracked | Git origin, main, docs and actual rule evidence; G0-CAMPAIGN-01 PR #3 merged; logo remains open | None on routine setup |
| C1 — Product & Design | PRD, traceable stories, UX flows, responsive prototypes, brand/spec, high-fidelity comparisons | 17-file Draft PR #5 exists; fix R01–R06; regenerate evidenced screenshots and contrast audit; commit updates to same PR; no app source | **One grouped visual/product review**: name/logo direction, key screens, feature scope |
| C2 — Architecture & CI preparation | Domain model; deterministic exercise catalog/plan safety constraints; persistence/photo/backup/privacy decisions; Android release signing design; CI configuration | Document tests/risks, independently verify package versions/licenses; CI workflow demonstrably green on exact current head when feasible; no code merge before CI | One combined review of major safety/data/dependency decisions |
| C3 — Flutter Foundation | P0 scaffold + P1 shell/theme/AR-EN RTL/navigation and reusable approved components | Flutter analyze/test/build, widget/golden/RTL checks and exact-head green CI on scoped PR, then guarded auto-merge | None if implements previously approved design |
| C4 — Smart Plan Engine | P2 catalog/local schema + P3 pure-Dart rule engine with recovery, equipment, progression and safeguards | Tests for no equipment, assistance vs resistance, pain stop, deload, missed days, migration, deterministic output; CI green | Safety gate must already be approved |
| C5 — Full Workout Loop | P4 onboarding/Today/start/Lite/log sets/rest timer/pause/resume/swap/summary | Automated Flutter/widget/state restoration and negative-case tests, build logs, exact-head CI, scoped merges | No routine approval |
| C6 — Progress | P5 photos/compare, weight trend, strength graphs, weekly consistency, meal checklist | Photo sandbox/privacy tests; chart math with sparse/missing entries, persistence and UI golden tests, CI/build | No routine approval |
| C7 — Reliability | P6 notifications, manual validated export/import, migration and restart recovery | Backup round-trip including photos; malicious archive input limits, interrupted restore, permission tests, CI/build | None unless privacy decisions differ |
| C8 — Release Candidate | P7 accessibility, performance, RTL/large text, security checks, offline manifest, APK signing/update plan; P8 private install docs | Release candidate signed APK, full regression logs, dependency/license inventory, install/update guidance; automated checks on exact head | Review readiness for final phone gate |
| C9 — Final Honor Acceptance | Wirelessly install on Honor X9e Pro, complete real 15–30min workout, Lite, photos/privacy, reminders, export/import, update and reboot | **Actual human phone evidence**; fix failures and rerun regression + final retest; only then release accepted | **Final approval** |

### C1 specifically: current and proposed long correction marathon
- **Current:** Draft PR #5 head `70aaacc2a72278e876163033a7a61b8542fb9c5e`, 17 changed files, 5 commits; `G1–G5` not approved, Issue #1 exact logo PNG pending, no Flutter code/CI.
- **Short previous prompt** would fix review R01–R06, generate some screenshots and update the same Draft PR; it does **not** create any Flutter app, end-to-end product design validation, or complete CI.
- **Extended C1-R:** execute entire review fix + visual implementation/QA cycle across responsive variants, RTL, high-text-scale, static/interactive prototype honesty, evidence screenshots, UX content polish, accessibility calculations and independent correction matrix; commit in small slices and consolidate one review-ready package. This is real productive work; not a fixed-duration timer.
- Do not finalise/merge C1 product designs until Ahmed reviews compiled images once. No app/runtime code before relevant owner gates.

## C1-R visual acceptance matrix
- Screens: Today, Workout Player + Rest, Onboarding, Progress, Edge/Recovery.
- Real browser renders (not only HTML text) at narrow ~360×800 and wide ~430×930 viewport; dark/light where meaningful; RTL Arabic, numeric LTR; text-scale 1.5×. Include actual screenshot files and verification method; if tool lacks rendering, label **UNVERIFIED**.
- Actual contrast calculations for text/surfaces/control states with formula and 4.5:1 regular text; 3:1 large text/components. Correct failures rather than merely claiming passes.
- Show state/pain-stop/swap behavior consistently as safe, non-medical, equipment aware.
- Preserve original Pull-Up Motion as owner-preferred only. Never replace missing exact PNG with lookalike; a neutral placeholder clearly marked as such is acceptable.
- Copy should sound natural Egyptian Arabic, no references to accounts, daily-streak guilt or BMI.
- Product scope unchanged and no unrelated dependencies or privacy assumptions.

## Release gates and explicit non-goals
- Long campaigns / merges are **conditional permissions**, not a promise of actual multi-hour runtime or zero interruptions.
- CI absent: implementation auto-merges blocked. Under owner authorization agent can design and configure CI in C2 once bounded.
- Private binary logo remains [Open], original source SHA in Asset Manifest; needs exact byte handoff. No fake vector.
- Safety choices (band assistance vs resistance, conservative joint-pain stop behavior, muscle loading) need human/technical review before coding.
- Package versions, font/media licenses, Android automatic backup and secure manual backup need independent verification at decision time.
- Do not invent accepted high-fidelity visuals or device acceptance from agent self-report.
- Extra friend training goals, cloud, accounts, AI runtime, iOS, online content, paid services remain post-MVP unless Ahmed explicitly changes scope.

## How to resume
Read GitHub source-of-truth and latest PR heads; identify live campaign, draft vs merged state, screenshots/evidence, required gates, and the **single next Product Owner decision**. Do not make Ahmed paste the same technical setup or approve routine steps.
