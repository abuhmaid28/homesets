# HOMESETS — Prospective Flutter CI Implementation Plan (Milestone P0+)

**Document Status:** [Prospective Architecture Plan]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Target Milestone:** Milestone P0 (Implementation Code Commencement)  
**Authority Reference:** `DECISION_REGISTER.md` (GOV08, GOV10), `docs/PROJECT_RULES.md`  

---

## 1. Scope & Transition from Foundation CI

Currently, `.github/workflows/foundation.yml` executes document links, secret hygiene, and domain fixture validation. It explicitly does **NOT** build Flutter application code.

When the Product Owner approves Gate G4 (Visual Direction) and Gate G6 (Architecture / Dependencies), Milestone P0 will initialize the Flutter project scaffold. At that point, the prospective pipeline below will be merged to enforce exact-head code CI before any runtime implementation code can be merged into `main`.

> [!IMPORTANT]
> This document is a specification plan only. Zero Flutter production code (`lib/`, `test/`) or `pubspec.yaml` dependencies are created in Campaign C2.

---

## 2. Prospective Exact-Head Flutter CI Workflow (`.github/workflows/flutter_ci.yml`)

```yaml
name: HOMESETS Application CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

jobs:
  verify-app:
    name: Flutter Lint, Engine Unit Tests & APK Build
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Setup Java Development Kit (JDK 17)
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter SDK (Pinned Stable)
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true

      - name: Install Approved Dependencies
        run: flutter pub get

      - name: 1. Strict Formatting Verification
        run: dart format --output=none --set-exit-if-changed .

      - name: 2. Strict Static Analysis
        run: flutter analyze --fatal-infos

      - name: 3. Domain Engine Isolation Gate
        run: |
          echo "Verifying zero Flutter imports in lib/domain/engine/..."
          if grep -rn "package:flutter" lib/domain/engine/; then
            echo "ERROR: Violation of ADR-001! Flutter imported inside pure domain engine."
            exit 1
          fi
          echo "PASS: lib/domain/engine is pure Dart."

      - name: 4. Manifest Security Audit (Zero Internet Permission)
        run: |
          echo "Verifying zero network permissions declared..."
          if grep -rn "android.permission.INTERNET" android/app/src/main/AndroidManifest.xml; then
            echo "ERROR: Violation of D02! Internet permission detected in AndroidManifest.xml."
            exit 1
          fi
          echo "PASS: Zero network permissions verified."

      - name: 5. Pure-Dart Engine Unit Tests with Coverage
        run: flutter test test/domain/engine/ --coverage

      - name: 6. Widget, RTL & Touch Target Tests
        run: flutter test test/presentation/

      - name: 7. Database Migration Roundtrip Tests
        run: flutter test test/database/

      - name: 8. Android Debug APK Compilation Build
        run: flutter build apk --debug
```

---

## 3. Guarded Merge Enforcement (GOV08)

In strict accordance with `docs/AGENT_AUTONOMY_POLICY.md`:
1. Local execution alone does **NOT** authorize merging implementation code into `main`.
2. Every pull request introducing Flutter code must be backed by a green run of this workflow on the exact head commit SHA.
3. If CI fails, is skipped, or times out, the PR remains unmerged until the defect is resolved.
