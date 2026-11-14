# HOMESETS — Campaign C1 Correction & Verification Matrix (R01–R06)

**Document Status:** [Final] — Audit & Resolution Matrix for C1 Review Corrections
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Target Pull Request:** [Draft PR #5](https://github.com/abuhmaid28/homesets/pull/5)
**Authority Reference:** `docs/DECISION_REGISTER.md` (D01–D20, GOV06–GOV11), Independent C1 Review on PR #5

---

## 1. Executive Correction Summary

This document verifies the end-to-end resolution of all six critical findings (**C1-R01** through **C1-R06**) raised during the independent review of Campaign C1 at head `70aaacc`.

All corrections have been committed on feature branch `campaign/c1-design-foundation` and pushed to Draft PR #5. **Zero production Flutter code was created or merged.** All design and architecture decisions remain proposals awaiting Product Owner gate review.

---

## 2. R01–R06 Detailed Audit & Resolution Matrix

| Review ID | Finding Category | Severity | Detailed Resolution & Files Modified | Verification & Proof |
| :--- | :--- | :--- | :--- | :--- |
| **C1-R01** | Accessibility Contrast Failure on `#71717A` | **High** | 1. Recalculated all color pairs with official W3C relative luminance formula.<br>2. Confirmed `#71717A` is **3.84:1** on `#121316` and **3.45:1** on `#1C1E24`, failing AA normal text (4.5:1).<br>3. Restricted `#71717A` strictly to non-text disabled controls / borders.<br>4. Introduced `#8E8E93` (5.70:1 on root, 5.11:1 on card) and `#9CA3AF` (7.32:1 / 6.56:1) as verified accessible tertiary text tokens.<br>5. Corrected advertised ratios: `#CCFF00` = 15.81:1, `#A1A1AA` = 7.25:1, `#365314` = 8.35:1.<br>**Files:** `docs/design/BRAND_GUIDELINES_DRAFT.md`, `docs/design/DESIGN_SYSTEM_SPEC_DRAFT.md`. | Reproducible Python test script `scratch/full_contrast_matrix.py` confirms all readable text tokens pass $\ge 4.5:1$ on all dark surfaces. |
| **C1-R02** | Android Backup Privacy & Non-Atomic Restore | **High** | 1. Added `data_extraction_rules.xml` specification for Android 12+ (API 31+) and Android 16 (MagicOS 10) separating `<cloud-backup>` and `<device-transfer>`.<br>2. Completely excluded `private_photos/` and `databases/` from Google Drive cloud backup.<br>3. Specified `android:allowBackup="false"` in manifest.<br>4. Added mandatory privacy warning dialog before Android Sharesheet invocation on manual export.<br>5. Added zip-bomb limits (500 MB max, 500 files max, 100:1 ratio) and path traversal (`..`) rejection.<br>6. Resolved non-atomic restore by designing a Two-Phase Staged Pipeline with `cache/pre_restore_snapshot/` rollback.<br>7. Corrected zero-network claim to OS kernel socket sandbox.<br>**Files:** `docs/architecture/ARCHITECTURE_OPTIONS_DRAFT.md`, `docs/product/MVP_TRACEABILITY.md`. | Architectural pipeline specification verified; failure recovery steps explicitly diagrammed. |
| **C1-R03** | Safety & Band Resistance/Assistance Logic | **High** | 1. Differentiated **Assistance bands** (pull-ups: heavier = easier; progression = reduce band thickness or unassisted) vs **Resistance bands** (push-ups/rows: heavier = harder; progression = increase band thickness or add reps).<br>2. Prohibited universal color ladders; progression is exercise-specific and user-calibrated.<br>3. Enforced **Acute Joint Pain Stop Precedence**: immediate stop and joint rest take absolute precedence; prohibited auto-prescribing alternative loaded exercises during acute pain.<br>4. Tagged all training progression and safety logic as **[Proposed pending qualified fitness safety review]**.<br>**Files:** `docs/product/PRODUCT_REQUIREMENTS_DRAFT.md`, `docs/product/USER_STORIES_AND_ACCEPTANCE.md`, `docs/product/MVP_TRACEABILITY.md`, `docs/ux/USER_FLOWS_DRAFT.md`, `docs/quality/CI_AND_TEST_MATRIX_DRAFT.md`. | User stories US-05 and US-06 rewritten; safety rules updated across all product specifications. |
| **C1-R04** | Static Prototype Labeling & Rendered Screenshots | **Medium** | 1. Relabeled all 7 HTML prototypes as **static visual prototypes** (no JS/simulated interactivity).<br>2. Removed hard-coded 844px height and `overflow:hidden`; implemented responsive scrolling viewports.<br>3. Labeled vector silhouette in previews as abstract temporary placeholder, not chosen final logo.<br>4. Generated real rendered offline PNG screenshots at multiple viewports (360×780, 390×844, 412×915, 900×950) using Chrome headless.<br>**Files:** `design/ux/*.html`, `design/explorations/*.html`, `design/screenshots/*.png`. | 14 real PNG screenshots generated and saved in `design/screenshots/` without third-party dependencies. |
| **C1-R05** | Architecture & Package Dependency Verification | **Medium** | 1. Verified candidate versions against pub.dev (November 2026): `flutter_local_notifications 23.0.2` (requires Dart >= 3.12), `drift 2.35.4`, `drift_flutter 0.3.1`, `intl 0.19.0`.<br>2. Added explicit policy guard: **Proposed candidates only; zero packages added to pubspec.yaml in C1**.<br>3. Corrected test runner command to `flutter test test/domain/engine/` and clarified zero test files currently exist.<br>4. Replaced unbenchmarked claims ("100+ tests in <2s") with architectural design targets.<br>**Files:** `docs/architecture/ARCHITECTURE_OPTIONS_DRAFT.md`, `docs/quality/CI_AND_TEST_MATRIX_DRAFT.md`. | Candidate dependency table updated with minimum SDK requirements and official sources. |
| **C1-R06** | Product UX, Scope & Terminology Consistency | **Medium** | 1. Fixed single confirmed MVP goal ("بناء العضلات والقوة"); removed onboarding goal selector; extra goals isolated to post-MVP.<br>2. Replaced pre-filled personal numbers with blank inputs and placeholder hints ("مثال: 175 سم", "مثال: 70 كجم", "مثال: 8 تكرارات").<br>3. Replaced `تهيئة الحساب` with `إعداد التطبيق وبدء برنامجك` (App Setup).<br>4. Defined 7-day rolling calendar average with sparse data guardrail (< 3 weigh-ins in 7 days = provisional, no advice triggered).<br>5. Clarified 15-minute Lite mode is target estimate.<br>6. Clarified 24 inventory entries include sheets, overlays, dialogs, and banners, not 24 mandatory top-level pages.<br>**Files:** `docs/product/PRODUCT_REQUIREMENTS_DRAFT.md`, `docs/product/USER_STORIES_AND_ACCEPTANCE.md`, `docs/ux/INFORMATION_ARCHITECTURE_DRAFT.md`, `docs/ux/USER_FLOWS_DRAFT.md`. | Terminology and scope aligned across all product and UX documentation. |

---

## 3. Residual Risks & Next Actions

1. **Brand Asset Ingestion (Issue #1):**
   - Status remains `ASSET_SOURCE_UNAVAILABLE`.
   - The original 2,018,426-byte PNG (`Neon-Lime Pull-Up Fitness Logo(1).png`, SHA-256 `95822f54...`) must be placed into `assets/brand/reference/homesets-pullup-preferred.png` before vector conversion in Gate G2.
2. **Product Owner Review Gate:**
   - Ahmed reviews the updated Draft PR #5, inspection screenshots in `design/screenshots/`, and the correction matrix.
   - Upon PO approval, the next campaign (Campaign C2: Architecture & CI Setup, followed by Milestone P0 Android Scaffold) can proceed.
