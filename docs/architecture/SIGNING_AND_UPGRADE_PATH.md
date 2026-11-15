# HOMESETS — Android Release Signing & Wireless APK Upgrade Specification

**Document Status:** [Active Technical Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D01, E03, GOV10, O08), `docs/PROJECT_RULES.md`  

---

## 1. Application Identity & Package Identifier

- **Application ID:** `com.abuhmaid.homesets`
- **Application Label:** `HOMESETS` (Arabic: `هوم سيتس`)
- **Distribution Model:** Personal sideloaded APK (Wireless install; no Google Play Store).
- **Target OS:** Android 12 (API 31) through Android 16 (API 36 / MagicOS 10 on Honor X9e Pro).

---

## 2. In-Place Wireless Upgrade Invariant (Zero Data Loss)

When Ahmed updates the app wirelessly on his Honor X9e Pro:
$$\text{Installed Signature} \equiv \text{Update Signature}$$
- If the cryptographic signing key changes between updates, Android Package Manager blocks installation with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
- The user would be forced to uninstall the app, which immediately purges the internal sandbox (`/data/user/0/com.abuhmaid.homesets/`), **permanently deleting all workout history and physique photos!**

### Invariants:
1. All release APKs must be signed with the **exact same private release keystore**.
2. `versionCode` must increment monotonically with every build:
   - v1.0.0 $\to$ `versionCode: 1`
   - v1.0.1 $\to$ `versionCode: 2`
   - v1.1.0 $\to$ `versionCode: 3`
3. Monotonic incrementing prevents Android Package Manager downgrade rejections (`INSTALL_FAILED_VERSION_DOWNGRADE`).

---

## 3. Keystore Security & Zero-Secrets Git Policy

In strict accordance with `PROJECT_RULES.md`:
> *"No secrets or private physique photos in Git; no commits of signing keys."*

### Security Configuration:
1. The release keystore (`homesets-release.jks`) and credential file (`android/key.properties`) are strictly ignored in `.gitignore`:
   ```gitignore
   # Android signing keys & credentials
   *.keystore
   *.jks
   android/key.properties
   ```
2. A non-sensitive template is maintained in version control:
   ```properties
   # android/key.properties.example (Committed template)
   storePassword=YOUR_KEYSTORE_PASSWORD_HERE
   keyPassword=YOUR_KEY_PASSWORD_HERE
   keyAlias=homesets
   storeFile=../homesets-release.jks
   ```
3. During development, automated CI workflows build unsigned debug APKs (`flutter build apk --debug`).
4. Ahmed generates the official release keystore once locally, storing the `.jks` file securely in his personal password manager / offline backup.

---

## 4. Android Signature Scheme v2 & v3 Compatibility

Honor X9e Pro runs MagicOS 10 (Android 16). Modern Android requires APK Signature Scheme v2 (full-file block verification) and v3 (key rotation support).

In `android/app/build.gradle`:
```groovy
android {
    signingConfigs {
        release {
            enableV1Signing true
            enableV2Signing true
            enableV3Signing true
        }
    }
}
```
Ensures APK verification passes on all modern Android Package Manager implementations without requiring USB ADB commands.
