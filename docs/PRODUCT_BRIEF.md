# HOMESETS — Product Brief (Draft)

## Problem
Ahmed wants to build muscle at home without a gym. Previous attempts stopped due to lack of schedule, boredom, and little visible evidence of progress. A useful product tells the user **what to do now**, chooses safe progression, shows photos + numbers, and adapts around irregular shifts.

## Target
- Initially one local user on an Honor X9e Pro; another private install later.
- Android-only Flutter, offline-first, no backend, zero recurring spend.
- Pull-up bar + resistance bands for Ahmed; exercises dynamically filtered by the selected equipment.
- Workouts 15–30 minutes, before work when practical; no strict weekday scheduling.
- Home strength and muscle-building, not medical advice.
- Android 16 (MagicOS 10), private wireless APK installation.

## Product principles
1. Start a workout in no more than 3 taps from Today.
2. One clear primary action per screen, large thumb-zone controls.
3. The app chooses an equipment-aware plan; the user can swap, skip or choose Lite.
4. Progress is measured by actual session logs, weekly weights and private photos, not vague promises.
5. Encouraging Egyptian Arabic, no guilt, daily streak pressure or body-shaming.
6. Work entirely offline; personal data never requires account creation.

## Daily experience
- Today: next workout + estimated time, Start, Lite and Swap.
- Workout player: current move, cues, reps, set logging, rest timer, quick easy/right/hard feedback and pain/stop action.
- End: short recap, progress and next session logic.
- Weekly: photo check-in, weight trend, progress chart, consistency, meal checklist.

## Safety and scope
- Conservative default progression, pain-based exclusions, stop/swap on pain.
- Rules under discussion: approximate 1–3 reps-in-reserve, workout spacing, recovery after absences, gradual progression; all need verification before runtime implementation.
- No diagnosis, BMI labels, aggressive weight advice or extreme plans.
- No calorie or macro tracker, cloud, subscription, public community, AI/LLM or social sharing in MVP.

## Core experience acceptance
On Honor: onboarding works; Today -> Workout within 3 taps; one-handed log and Lite work; missed-days recovery is correct; private photo compare and weekly weight trend work; backup round-trip; RTL layouts correct; all features offline; no crash on interruption or application update.

## Deliberate open questions
- Exact band strengths; supported safer exercise substitutions.
- Exercise demonstration medium/license.
- Friend onboarding with a different goal vs build-muscle-only MVP conflict.
- Android auto-backup policy; MagicOS notification behavior.
- Logo/font/adaptive icon technical acceptance.
- Approved dependencies and persistence architecture.

See [Master Prompt](MASTER_PROJECT_INITIALIZATION_PROMPT.txt), [Decision Register](DECISION_REGISTER.md), [Roadmap](ROADMAP.md).
