# HOMESETS — Autonomous Delivery Runbook (Long Campaigns)

Date: 2026-11-14
Status: [Recommended execution playbook], aligned with [Confirmed] owner-approved GOV06–GOV11.
Authority: `docs/DECISION_REGISTER.md`, `docs/AGENT_AUTONOMY_POLICY.md`, `docs/ROADMAP.md`, `docs/MASTER_EXECUTION_PLAN.md`.
Purpose: prevent repeated small prompts, duplicated work, idle waiting for routine approvals, and losing progress across model/agent sessions.

## What the owner actually wants
Ahmed is Product Owner only. He has already sent a **short R01–R06 repair prompt** to Antigravity. **Do not interrupt, restart, or launch a competing campaign over that work**. Once it finishes and the current branch/PR state is verified, run a **long, bounded campaign** that reads the GitHub backlog and autonomously performs successive productive work packages, tests, fixes, commits and documented handoffs.

No arbitrary time wasting: campaign size is measured by real deliverables (multiple meaningful work packages) rather than artificially staying busy. Model quota, session or machine may interrupt work; checkpoint safely and resume. GitHub issues and documents do **not** autonomously start Antigravity on Ahmed's computer.

## Immediate current state and synchronization
- C0 foundation: doc-only PR #3 merged, G0 partial due to missing exact owner-preferred PNG; workspace Git linkage evidenced by agent log and repository artifacts.
- C1: Draft PR #5, feature branch `campaign/c1-design-foundation`, initial head `70aaacc2a72278e876163033a7a61b8542fb9c5e`, 17 files, five commits. R01–R06 independent review exists; short correction task was **already sent** by Ahmed. Actual result **not yet supplied** in this chat.
- C1-R Issue #6: extended visual / responsive / independent QA campaign **prepared, not yet executed**. It must inspect the newest Draft PR head and **skip any R01–R06 corrections already done** rather than overwriting or duplicating changes.
- CI absent; logo binary missing from repo; Flutter code not started. No code merge before required exact-head CI + design/product/safety approvals.

## Campaign lifecycle (each campaign)
**0. Resume:** Check repo root/origin, branch, clean/dirty state; read actual active issues, latest PR head and all canonical decisions. If another Antigravity run is active on same branch, STOP to avoid parallel edits.
**1. Plan:** Read preapproved goal/scope/out-of-scope, decompose into substantial work packages (typically 5–8) with objective completion tests, risk-ranked steps and stop conditions. This is internal planning, not a request for a routine owner approval.
**2. Execute:** Work through packages sequentially. Use short internal commits/snapshots after verified chunks, not a single dangerous massive commit.
**3. Verify:** Reproduce tests against actual changes, inspect diff, run architecture/privacy/RTL/accessibility checks; for implementation, require full `flutter analyze`, `flutter test`, `flutter build apk` and exact-head CI.
**4. Repair:** Automatically fix in-scope failures; re-run failed checks; do not claim PASS without raw evidence. Do not skip failures to achieve a merge.
**5. Publish:** Push feature branch, update PR/issue, cite exact SHA and evidence. For docs/proposals with pending owner design decision: leave **Draft PR unmerged**. For approved runtime scope: merge normally only after all guarded CI conditions in current policy.
**6. Continue or stop:** Continue automatically into the next work package in the **same authorized campaign**, but do not jump across an unmet Product Owner design/safety gate, new dependency approval, paid/external service, missing required source, unverified CI, wrong repo or destructive operation.
**7. Handoff:** Leave a machine-readable-ish Markdown checkpoint under `docs/campaigns/` with COMPLETE/PARTIAL/BLOCKED by WP, exact branch and head SHA, files changed, tests/exit codes, PR state, remaining blockers and safest next package. If interrupted, another agent run resumes from this, not guesses.

## End-to-end plan (campaigns vs milestones)
| Campaign | Scope | Major deliverables and internal verification | Unlocks |
| --- | --- | --- | --- |
| C0 FOUNDATION | GitHub/private repo, rules, original master, decisions, workspace | Repo identity, rules, docs review; exact PNG tracked and checked when available | G0 groundwork; logo remains open |
| C1 DESIGN MARATHON | G1–G5 product/brand/UX | PRD, user flows, responsive Today/Workout/Onboarding/Progress, full Dark/Light and AR RTL, visual screenshot QA, design tokens and color accessibility, owner review package | ONE grouped PO approval of product + brand + screen direction |
| C2 ARCHITECTURE + CI | G6–G7 | Deterministic safety specification and tests; local DB/photos/backup/notification choices; dependency/license review; Android rules; CI workflow real run | Approved architecture/dependencies + valid CI gate |
| C3 FLUTTER FOUNDATION | P0–P1 | Flutter app scaffold, offline Android, localization/theme/components/navigation, golden/widget tests and APK build | Automated artifact ready, no intermediate phone gate |
| C4 ENGINE + DATA | P2–P3 | Versioned local schema, exercise catalog, progressive plan engine, recovery and safe-stop logic, exhaustive pure Dart scenario tests | Real workout logic safely unit-tested |
| C5 WORKOUT USER JOURNEY | P4 | Onboarding, Today, Lite, Workout Player, logs/feedback, pause/resume, timer, summary, state/regression tests | Full core workout journey in APK |
| C6 PROGRESS | P5 | Private images, compare, weight/strength charts, weekly consistency, meal checklist with persistence/semantic tests | Progress evidence and UX |
| C7 BACKUP + NOTIFICATIONS | P6 | Private validated archive export/import, cloud backup restrictions, notifications on Android and MagicOS limitations; malicious/corrupt backup tests | Offline reliability |
| C8 POLISH + RELEASE | P7–P8 | accessibility, device-independent performance, privacy/security/regression, signed APK strategy, install/update guide | Release candidate for Honor |
| C9 HONOR ACCEPTANCE | Final | Ahmed manually tests on Honor X9e Pro after wirelessly installing APK, logs defects, final rework/retest | Accepted MVP |

For each code campaign C3–C8, 1 long authorization can include several small slices and PRs. Continue automatically between slices after **actual** green checks and in-scope approvals. No manual phone gate until C9 (explicit GOV07).

## Gate policy — exactly when Ahmed must make a decision
**Major gate 1:** One visual/product selection after design marathon (HOMESETS working name, exact preferred Pull-Up Motion logo direction, colors/typography, key screens, user journeys). Until then C1 may iterate but must not label brand FINAL or merge design directions.
**Major gate 2:** One safety/privacy/architecture acceptance before production logic dependencies/code (exercise progression and pain-stop policies, local backup/photo decisions, real license compatibility).
**Major gate 3:** Single final integrated Honor phone testing and acceptance after build (new fixes may require re-test).
All routine commands, refactors, documentation, tests, safe commits and PR status updates stay with agent/ChatGPT.

## Never silently expand scope
No other repositories, paid services, cloud accounts/backend, online AI, iOS, social, new training goal in MVP, new/unapproved dependencies, broad global Turbo filesystem permission, destructive Git operations, force push, bypassed security or unresolved critical safety/privacy issue.

## Current short task versus next long task
**Current short prompt:** fixes six C1 review findings and produces initial screenshots on existing Draft PR #5. Already submitted; wait for its actual completion evidence (no parallel changes).
**Next long prompt after current result:** run Issue #6 as a **continuation** of the corrected PR; avoid duplicate fixes, expand into exhaustive responsive design iterations and QA, then deliver ONE consolidated visual decision package. This is the only next agent prompt needed now.
**After owner design approval:** run C2 as a long architecture/CI campaign with another carefully scoped issue; then C3–C8 implementation campaigns autonomously with guarded merges. It is not safe to pre-authorize their unknown dependencies and final branding by one blanket instruction.

## No false progress
A live issue, prepared prompt, GitHub commit or agent narrative is not evidence of executed tests or accepted design. Report separate states: AUTHORIZED / STARTED / VERIFIED TECHNICALLY / OWNER APPROVED / MERGED / DEVICE VERIFIED. Actual device test belongs to C9 only.
