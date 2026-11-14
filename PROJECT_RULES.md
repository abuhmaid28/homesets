# HOMESETS — Project Rules (Agent-facing, current)

## Must-read source of truth
Read `docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt`, `docs/DECISION_REGISTER.md`, `docs/AGENT_AUTONOMY_POLICY.md`, `docs/PROJECT_STATUS.md`, `docs/ROADMAP.md`, and `docs/BRAND_DIRECTION.md` before starting a campaign. The Master Prompt is the **immutable historical baseline**; later **explicit** owner decisions GOV06–GOV11 supersede its requirement for per-milestone physical phone tests and its old no-merge default, but not the product/safety scope.

## Roles and operating style
- **Ahmed:** Product Owner, approves important product/brand/safety choices and final phone acceptance. Never request routine commands, uploads, repeated approvals or Git chores from him.
- **ChatGPT:** plans tasks, updates GitHub source of truth, independent reviewer.
- **Antigravity:** execute long bounded campaigns autonomously; split into tiny internal slices, run checks/fix failures, commit/push/create PR, and **merge only after all gates** in the approved policy.
- Continue without asking for routine code edits, refactoring within approved files, minor UI implementation decisions, tests, retries or clean commits. Ask **only** on actual stop conditions.

## Absolute scope and safety restrictions
- Only operate inside the verified `abuhmaid28/homesets` workspace/repository. Never access EgyHealth360, agent-performance-lab or unrelated user folders.
- No force push, deleting other user data, disabling safety controls, sharing secrets, commits of signing keys or private physique photos, paid services, unapproved network/backend, cloud sync, accounts or Play Store.
- Do not add/change dependencies, SDK/tool versions or package licenses without prior specific authorization; document candidate options for review instead.
- No out-of-scope feature or decision changes. Preserve explicitly Confirmed brand choices; HOMESETS and Pull-Up Motion are **preferred**, not approved final assets.
- Flutter Android only, offline-first; no app network permission without owner change; Egyptian Arabic RTL first, English optional, dark/light system, free assets with provenance.
- Not medical advice: conservative progression, equipment/avoid-area filtering, stop/swap for pain, recovery spacing, no BMI/shaming/extreme or unsafe recommendations.
- If repo state, source asset, safety logic, licenses or approved scope are unclear: STOP with a single concise blocker. Never substitute lookalike images for the exact selected logo.

## Quality, Git and merge conditions
1. Inspect exact repo origin, branch, root, changes, commit and active workspace agent rules. Stop for unknown/dirty unrelated state.
2. Perform multiple scoped tasks continuously with **small commits and runnable automated checkpoints**.
3. Verify raw `flutter analyze`, `flutter test`, relevant feature tests and `flutter build apk` results when Flutter exists; text-only stages use suitable documentation/diff checks. Never claim a test ran unless its real output is provided.
4. Before **implementation code merge**, exact PR-head GitHub CI must be genuinely **green** and mandatory checks must exist and not be skipped or stale. Review changed paths, dependency updates, privacy/safety and regression findings. No bypass when check fails or is unavailable.
5. Within approved scope, a normal (non-force) PR merge may proceed automatically after all required gates pass. GitHub's built-in Auto-merge is not necessarily enabled; do not promise its availability.
6. Record commit SHAs, test logs, PR/merge URLs, known issues, rollback plan, unresolved device-only limitations. Update status.
7. **Do not wait for Ahmed's phone test at P0–P8.** Physical Honor test is deferred to **final integrated acceptance** by his explicit 2026-11-14 decision. Until then, device behavior is UNVERIFIED.
8. No final MVP Done or release until Ahmed confirms the actual end-to-end Android 16/MagicOS 10 phone test (wireless APK, no USB) and defects are resolved.

## Agent deliverable per campaign
Goal/scope; actual branch/origin evidence; files/commits/PRs/merges; raw check outputs and exit codes; signed/unsigned APK artifacts where applicable; failures/corrective steps; open questions, status and next ready campaign. No fabricated results.

## Permissions
Prefer HOMESETS-scoped Auto/sandbox and file access restrictions; avoid global Turbo/full filesystem permissions. Actual installed Windows Antigravity mode must be checked and recorded; `PROJECT_RULES.md` by itself does not prove automatic rule discovery. Create/check an active workspace rule when authorized.

**Current status:** repository docs exist; local link, CI, image asset and app are not yet verified as completed. Do not claim otherwise.
