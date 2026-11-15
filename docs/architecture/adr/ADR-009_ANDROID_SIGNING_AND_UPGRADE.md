# ADR-009: Android Release Keystore Management & Wireless APK Upgrade Path

- **Status:** Recommended (Architecture Baseline)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D01, E03, GOV10, O08), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

HOMESETS is a private Android application distributed exclusively via personal APK installation (no Google Play Store) (D01). Ahmed installs builds wirelessly onto his Honor X9e Pro (MagicOS 10 / Android 16) without connecting via USB cable (E03).

When updating an already-installed Android APK wirelessly, Android requires:
1. The new APK must be signed by the **exact same cryptographic key** as the currently installed build. If the signing key changes, Android Package Manager halts with an unresolvable `INSTALL_FAILED_UPDATE_INCOMPATIBLE` error, forcing an uninstallation that wipes local app databases and private photos!
2. Signing keys and keystore passwords must **never be committed to Git** (PROJECT_RULES.md).
3. The package ID must remain permanent (`com.homesets.app` or similar).

How should keystore generation, offline signing, and versioning be architected to ensure lifetime seamless wireless updates without risking key loss or secret exposure in version control?

---

## Decision Drivers

1. **Zero Data Loss on Update:** Seamless in-place updates without requiring app uninstallation.
2. **Absolute Git Hygiene (PROJECT_RULES.md):** Zero keystores, certificates, or passwords committed to repository.
3. **Reproducible Local Signing:** Clear, documented keystore creation process for local release builds.
4. **Android 16 / MagicOS 10 Compliance:** Proper APK v2/v3 signature scheme compatibility.

---

## Considered Options

- **Option A: Pinned Local Release Keystore + Git-Ignored Config (Recommended)**
  - Package ID fixed to: `com.abuhmaid.homesets`.
  - `key.properties` and `*.keystore` / `*.jks` added to `.gitignore`.
  - Standard template `key.properties.example` documented in repository.
  - Development builds use standard debug key; release builds use the local release keystore backed up safely off-repo by Ahmed.
  - Android Gradle configured to sign with Scheme v2 and v3.
- **Option B: Committing Keystore into Git**
  - Severe security violation; leaks cryptographic signing keys into version control history.
- **Option C: Re-generating Keystore on Every Build**
  - Breaks APK upgrade path; Android blocks all wireless updates unless the app is uninstalled first, causing complete database and photo loss.

---

## Decision Outcome

**Chosen Option:** **Option A: Pinned Local Release Keystore with Git-Ignored Configuration**.

### Upgrade Invariants:
1. `versionCode` must increment monotonically with every build (e.g. `versionCode 1`, `2`, `3`).
2. `versionName` follows semantic versioning (`1.0.0`, `1.0.1`).
3. `android/app/build.gradle` enforces signing configs via external `key.properties`.
4. In Milestone P8 and release packaging, explicit verification of APK signature compatibility scheme v2/v3 will be documented for Honor MagicOS 10.
