# HOMESETS — C2 CI Preflight & Pure-Dart Test Suite Specification

**Document Status:** [Final Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-14  
**Target Milestone:** Campaign C2 (Pure-Dart Engine & CI Initialization)  
**Authority Reference:** `docs/DECISION_REGISTER.md` (GOV07, GOV08, GOV10), `docs/AGENT_AUTONOMY_POLICY.md`  

---

## 1. Quality & Guarded Merge Pre-Flight

In accordance with `docs/AGENT_AUTONOMY_POLICY.md` and Decision GOV08:
- No implementation Pull Request may be merged to `main` until an exact-head GitHub Actions workflow reports green.
- This document specifies the exact GitHub Actions workflow and the initial pure-Dart test suite to be created at the start of Campaign C2.

---

## 2. Pure-Dart Plan Engine Test Matrix (Target: $\ge 95\%$ Domain Coverage)

The workout engine lives in `lib/domain/engine/` with zero Flutter dependencies. The initial unit test suite in `test/domain/engine/` will cover the following scenarios:

```text
test/domain/engine/
├── progression_test.dart       # Double progression ladder & overload validation
├── recovery_spacing_test.dart  # 24-48h muscle recovery collision checks
├── absence_deload_test.dart    # Absence penalty prevention & re-entry deload
├── joint_safety_test.dart      # Pain stop filter & avoid area exclusion
└── lite_mode_test.dart         # 15-minute tired day routine reduction
```

### 2.1 Concrete Scenario Test Specifications

| Test ID | Test Scenario | Input State | Expected Engine Calculation |
| :--- | :--- | :--- | :--- |
| **ENG-01** | **Double Progression Advance** | User completed 3 sets × 10 reps (top of 8–10 bracket) on Pull-ups with exertion rated "مظبوط ومثالي". | Recommends progressing load (+1.25kg or lighter assistance band) and resetting target bracket to 3 sets × 8 reps. |
| **ENG-02** | **Plateau / Fatigue Hold** | User achieved 8, 7, 5 reps (under target) with exertion rated "على الآخر (أقصى مجهود)". | Maintains current load for next cycle; suggests adding 30s rest interval; flags potential fatigue accumulation. |
| **ENG-03** | **Muscle Recovery Window** | Session containing Pull-ups & Bent Rows (Lats/Biceps primary) completed on Monday 18:00. | When query next workout for Tuesday (24h mark), engine schedules Leg/Core routine, strictly holding Pull routine until Wednesday (48h mark). |
| **ENG-04** | **Re-entry Deload on Absence** | User logs last workout 12 days ago. No sessions logged since. | Next workout marked "إعادة تنشيط (Re-entry)"; reduces total sets by 33% (2 sets instead of 3); reduces target reps by 2 to prevent severe delayed onset muscle soreness. |
| **ENG-05** | **Joint Pain Immediate Exclusion** | User reports acute shoulder pain during Overhead Press and triggers Pain Stop. | Engine records partial set; excludes all overhead pressing movements from upcoming rotation; substitutes pain-free lateral raises or band pull-aparts. |
| **ENG-06** | **Lite Mode Set Reduction** | User activates "⚡ وضع الإرهاق السريع (15 دقيقة)" for Today's workout. | Engine prunes accessory exercises, isolates primary compound lift to 2 high-intensity working sets, capping estimated duration at 15 minutes. |

---

## 3. GitHub Actions CI Workflow Specification

The following workflow file will be initialized at `.github/workflows/ci.yml` upon commencement of Milestone P0 / Campaign C2:

```yaml
name: HOMESETS CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify:
    name: Code Quality & Engine Verification
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Setup Java Development Kit
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter SDK
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install Dependencies
        run: flutter pub get

      - name: Verify Code Formatting
        run: dart format --output=none --set-exit-if-changed .

      - name: Strict Static Analysis
        run: flutter analyze --fatal-infos

      - name: Enforce Architecture Layering
        run: |
          echo "Verifying zero Flutter imports in domain engine..."
          if grep -rn "package:flutter" lib/domain/engine/; then
            echo "ERROR: Flutter package imported inside lib/domain/engine/!"
            exit 1
          fi
          echo "Architecture boundary verified: lib/domain/engine is pure Dart."

      - name: Run Pure-Dart Engine Unit Tests
        run: flutter test test/domain/engine/ --coverage

      - name: Compile Debug APK
        run: flutter build apk --debug
```

---

## 4. Verification Checkpoint

This preflight document provides full verification criteria for Campaign C2. No implementation code will be authored until this specification and the C1-V2 review package receive formal Product Owner review.
