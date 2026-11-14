# HOMESETS — Project Roadmap & Acceptance Gates

Status: **Draft plan for owner review**. This is NOT authorization to implement or add dependencies.
Grounded in the original Master Project Initialization Prompt, sections 5, 6, 12, 16 and 19.

## Planning and design gates (before application implementation)

| Gate | Goal | Exact scope | Acceptance / exit |
| --- | --- | --- | --- |
| G0 — Governance & source of truth | Prevent lost context and unapproved changes | Private GitHub, master prompt, decision register, current status, work rules | Files readable on GitHub, conflicts explicit, owner reviews; preferred reference logo uploaded |
| G1 — Product Blueprint | Freeze an achievable MVP | Personas, constraints, user journeys, features, scope exclusions, safety and UX constraints | Owner signs off scope; non-goals captured; no unapproved features |
| G2 — Brand Identity | Create durable brand assets | Candidate name, pull-up concept, typography proposal, icon variants and license evidence | Small-size/monochrome/adaptive-icon checks + final explicit owner approval |
| G3 — UX Design | Make the daily training journey effortless | Information architecture, user flow, sketches/wireframes, handling missed days, Lite sessions, pain/stop interaction | Owner reviews Today → Workout → Summary and onboarding; key states accounted for |
| G4 — Visual Design System | Establish reusable UI language | Token roles, typography, contrast, spacing, radius, component states, localization/RTL, dark and light themes | Approved design-system specification; no Flutter code yet |
| G5 — High-Fidelity Screen Design | Validate the desired appearance and usability | Pixel-level references for key flows; device-sized prototypes, responsive text and accessibility review | Owner approves representative Today / Workout / Progress screens |
| G6 — Architecture & Execution Plan | Make implementation safe and maintainable | Domain/data boundaries, deterministic plan engine, backup/photos, options for storage/state, offline policy, test plan | Architecture and dependency decisions documented, no new packages chosen without owner approval |
| G7 — Antigravity Workspace Setup | Control the coding agent | Local folder cloned from GitHub, actual Rules path verified, review mode, narrow task briefs | Workspace points to correct repo; no code produced until gate is approved |

**No production Flutter implementation before the relevant upstream gates are accepted.** Any exception needs a written owner decision with the cost and impact recorded.

## Runtime milestones (original P0–P8 retained)

All runtime milestones must produce command logs and be tried on the **actual Honor X9e Pro** before moving to the next. No USB connection; APK transfer and manual installation.

| Milestone | Goal | Build/test acceptance | Real-device acceptance |
| --- | --- | --- | --- |
| P0 — Bootstrap | Create a reproducible Android-only hello-world | Git repo cloned, project scaffold reviewed; `flutter analyze`, `flutter test`, `flutter build apk --debug` outputs supplied | APK installed wirelessly and launched on Honor X9e Pro; no crash |
| P1 — Foundation | UI shell, theme, design tokens, AR/EN RTL | Widget tests for theme/localization, analyzer clean | Design gallery and sample screens visible on phone, Dark/Light and RTL checked |
| P2 — Local data | Versioned schema, migrations, validated exercise catalog | Migration, JSON/schema and persistence tests supplied | Exercise catalog works offline, data survives restart |
| P3 — Plan engine | Pure-Dart rule engine and progression | Tests cover session selection, recovery, Lite, progression, pain avoid areas, missing equipment and missed days | Sample generated weeks reviewed on phone with Ahmed |
| P4 — Core loop | Onboarding, Today, Workout player | UI and interrupted-session resume tests, analyzer clean | Real 15–30 minute workout logged one-handed; interruption resumes safely |
| P5 — Progress | Photos, weight trends, strength and weekly consistency, meal checklist | Data/aggregate tests, photo-private-storage checks | Capture/compare photos on Honor; trends match manually checked results |
| P6 — Reminders and backup | Local optional notification, export/import with validation | Backup round-trip tests, notification permission checks | Reminder tested on Honor or limitation documented; import restores data/photos |
| P7 — Polish & release | Accessibility, performance, update and privacy validation | Release APK, code/data tests, manual regression evidence | Install signed APK then update over itself without data loss |
| P8 — Private sharing | Friend-ready install guidance | Updated docs / privacy assurance | Friend can install and onboard with supported settings; additional goals require separate scope decision |

## MVP features (must not silently expand)
- First-launch setup; one-card Today; 15-minute Lite; exercise swap.
- One-handed workout player, set/reps logging, rest timer, difficulty feedback.
- Rule-based equipment-aware progressive sessions and recovery.
- Private physique photos, side-by-side compare, weight trend, strength and weekly consistency.
- Cheap-protein ideas and meal checklist, no calorie/macros.
- Local optional reminders; manual export/import backup; Arabic-first RTL and English.
- Offline operation, no accounts, backend, sync or Play Store.

## Excluded unless a separate explicit scope decision is made
Cloud, accounts, server, payment, subscription, AI/LLM runtime, calorie counting, macro tracking, wearables, social features, iOS, public store publishing, additional fitness goals.

## Mandatory agent delivery for every implementation milestone
- One-sentence goal; context; approved files/areas and out-of-scope.
- Requirements, exact acceptance criteria, no unapproved dependency.
- Verification commands and **full actual output**, changed-file inventory, commit SHA.
- Known issues and stop conditions.
- Ahmed's **real-device evidence**, not an agent's assertion.
- Git commit only after verified milestone (or reviewed scoped candidate commit per workflow).

## Explicit unresolved conflict
Original Section 5 says MVP goal = build muscle; Section 16 P8 mentions onboarding with a *different goal*. Treat new goals as post-MVP pending owner decision; do not implement them now.
