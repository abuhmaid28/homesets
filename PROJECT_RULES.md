# HOMESETS — Project and Agent Rules

**Read first:** `docs/MASTER_PROJECT_INITIALIZATION_PROMPT.txt`, `docs/DECISION_REGISTER.md`, `docs/PROJECT_STATUS.md`, `docs/ROADMAP.md`.

## Authority
- Ahmed is Product Owner; only an explicit owner decision changes a [Confirmed] item.
- Do not treat [Recommended] or [Open] as approval.
- If documents disagree, STOP and request clarification.
- No production code before the applicable planning, brand, design and architecture gates are approved.

## Scope and coding
- Work only on the files explicitly allowed by the current Agent Task Brief.
- Never add a dependency, change SDK/version, move data, refactor unrelated code, or run destructive commands without approval.
- Offline-first and no network permission, server, account, analytics, advertising or paid APIs.
- Flutter Android only; private APK; Arabic Egyptian user copy, Arabic RTL first, English supported.
- Favor the simplest implementation with a pure-Dart deterministic workout plan engine.
- Keep private images inside app-private storage, never public gallery.
- Do not commit secrets, signing keys or personal fitness photos.

## Safety
- This is not medical advice. No diagnoses, BMI labeling, shaming, extreme loading or unsafe training recommendations.
- Avoid-area filtering, pain stop/swap, conservative progression, recovery and substitutions are essential.
- If a rule could create a risky workout, stop and request owner review.

## Evidence and workflow
- No claims of PASS without raw `flutter analyze`, `flutter test`, build output and relevant changed-file evidence.
- An Antigravity success message is a claim, not proof.
- Every implementation milestone requires an APK test on Honor X9e Pro before progressing.
- Owner does not want USB: test through wireless file transfer and manual APK install.
- Use a small scoped task and stop if ambiguous. Do not auto-merge or deploy.
- Recommend a Git commit after owner-verified milestones.

## Required report from implementation agent
1. Goal and scope executed.
2. Exact file list and diff summary.
3. Real command output and versions.
4. APK path when relevant.
5. Issues and unverified items.
6. Explicit device-test checklist for Ahmed.
7. Stop without declaring milestone complete.

**Note:** This document is an agent-readable reference. Whether Antigravity automatically loads it is **unverified**. Verify supported workspace rule filename/path before trusting automation.
