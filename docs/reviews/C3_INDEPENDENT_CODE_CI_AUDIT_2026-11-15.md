# HOMESETS — Independent C3-MEGA source and CI audit

**Reviewed:** 2026-11-15. **Review status:** **NO-GO for runtime merge**, corrections required. This review distinguishes actual GitHub evidence, agent-reported local commands, and tests not independently performed.
**Scope:** [Issue #11](https://github.com/abuhmaid28/homesets/issues/11), [Draft PR #12](https://github.com/abuhmaid28/homesets/pull/12), [GOV12–GOV19](../DECISION_REGISTER.md).

## Evidence verified directly via connected GitHub
- Prior C3 implementation PR head `9bcd72fefe1f43dbc7db2981837f65cc5886158b`: real Flutter source, tests and Android scaffold; PR initially Draft with 91 paths and 6 commits.
- The `docs/quality/workflows/flutter_ci.yml` file was **only a proposal**, not an active workflow. Earlier check runs for the old head = 0.
- ChatGPT created active `.github/workflows/flutter.yml` on `campaign/c3-flutter-core`, commit `e5914ae16b956f3662959bf60dae87a3b50bc290`; PR now shows 92 files/7 commits and remains **Draft/unmerged**.
- GitHub Actions starts two workflow runs: [PR run #43668524163](https://github.com/abuhmaid28/homesets/actions/runs/43668524163) and [push run #43668519943](https://github.com/abuhmaid28/homesets/actions/runs/43668519943). At last inspection, both **in_progress**, foundation job success, Flutter build/test job **not yet complete**. **Do NOT record CI PASS until both required jobs finish green on exact head.**
- Source `android/app/src/main/AndroidManifest.xml` lacks INTERNET, while `android/app/src/debug/AndroidManifest.xml` and `profile/AndroidManifest.xml` explicitly request INTERNET for Flutter tooling. Agent's claim that Debug APK has 0 network permissions is **not established**.
- `pubspec.yaml` includes conditional-approved app packages plus additional direct `path`, `cupertino_icons`, `flutter_lints` and dev `sqflite_common_ffi` not explicitly in GOV16 allowlist. Need explicit reconciliation/justification, not assumed approval.
- Supplied agent logs claim `flutter analyze` clean, `flutter test` 22/22, 4/4 Python suites, and local debug APK (181.76 MB, SHA-256 `48A2CAF6E8196CDFA5A409083A64E6310F3B00F64CFF17C83F90BF37562C917F`). These outputs are **AGENT-REPORTED**; GitHub independent CI not yet finished. APK is not downloaded/verified by ChatGPT.
- Agent validates 106 fixture scenarios **as Python schema**, not equivalent to 106 Dart workout-engine scenario tests; currently 8 Dart domain tests.

## Source-code issues requiring regression proofs before merge
- **C3R-01 CRITICAL:** `lib/domain/engine/workout_engine.dart` unconditionally accesses `eligibleExercises.first` in Lite Mode. If all equipment/joints excluded and even push/squat ineligible, RangeError; Standard may yield empty workout.
- **C3R-02 HIGH:** `lib/features/today/today_screen.dart` always requests routine A; engine merely rotates A→B within 36h, so true A/B/C progress is not maintained. `DateTime.now()` and session ID generated inside engine prevent fully deterministic output.
- **C3R-03 HIGH:** `WorkoutRepository.saveActiveSessionState` writes `active_session_json: '{}'` without full session. Resume on Today passes new Standard session instead of the original Lite/rotation. `_handleLogSet` records `currentSetIndex=_setIndex+1` even at end of exercise.
- **C3R-04 HIGH:** Pain STOP button opens a dialog and does not freeze immediately on first tap. Completed session flag is written but permanent joint quarantine / future avoidance not persisted by the available code path.
- **C3R-05 HIGH:** Catalog `chinup_neutral` eligible with ordinary bar despite `hasParallelGrip=false`; incline pushup guidance assumes chair/wall with no explicit verified platform distinction. Enforce capability rules.
- **C3R-06 HIGH:** Incorrect zero INTERNET claim for debug APK; distinguish main/release from merged debug variant.
- **C3R-07 MEDIUM/HIGH:** Weekly consistency query counts all recorded sessions within rolling 7 days, including emergency pain-stopped sessions, not explicitly local calendar week.
- **C3R-08 HIGH GATE:** Non-allowlisted direct dependencies need reconciliation before eligible merge.
- **C3R-09 MEDIUM:** 106 fixtures validated structurally, only 8 Dart engine tests. Missing full negative safety and process restart test matrix.
- **C3R-10 MEDIUM:** `main.dart` Settings button resets `_hasProfile=false` and shows onboarding instead of editing existing profile, with potential unintentional resetting of user equipment/avoided joints.
- **ACCESSIBILITY:** WCAG contrast computed directly for `HomesetsColors.textMuted #5E6473` against background `#121417` = **3.12:1**. It fails normal 4.5:1 threshold if rendered as ordinary small text; audit actual usage and correct tokens or roles.

These are **code-reading findings and actionable reproduction requirements**; no claim that the reviewer ran Windows Flutter or demonstrated the crashes on the physical Honor device.

## Review actions and next gate
- [PR review #5908647769](https://github.com/abuhmaid28/homesets/pull/12#pullrequestreview-5908647769) recorded **NO-GO** findings.
- [C3R-MEGA Issue #13](https://github.com/abuhmaid28/homesets/issues/13) includes a long 12-WP autonomous repair/testing/CI campaign, within owner-approved P0–P4 scope. It may fix and commit tests continuously; **no owner routine approval** and **no PR merge until independent green exact-head CI plus review**.
- Do not initiate P5–P8, final signing or Honor manual phone test. GOV07 explicitly defers device acceptance to final C9.
- Before the agent starts, its local C3 branch must `git fetch` and safely fast-forward to the new CI commit; no force push/merge unrelated PRs.
- Next reviewer action: inspect actual Actions conclusions and the new PR head after C3R; do not mark C3 as fully accepted from self-report.
