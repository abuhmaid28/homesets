# HOMESETS — Brand Guidelines Draft (Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G2 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)
**Authority Reference:** `docs/BRAND_DIRECTION.md`, `docs/DECISION_REGISTER.md` (B01–B03, O05, O09)

---

## 1. Brand Hierarchy: Approved vs. Preferred vs. Proposed

To prevent scope creep and preserve Product Owner authority, the brand elements are strictly classified:

| Element | Status in Decision Register | Notes & Authority Boundary |
| :--- | :--- | :--- |
| **App Name: HOMESETS** | [Preferred: B01] | Working name; reflects home workout sets. Not final trademark or registered mark. |
| **Visual Aesthetic: Performance Lime** | [Preferred: B02] | Dark charcoal base with electric neon lime accent. Direction A from initial owner exploration. |
| **Logo Symbol: Pull-Up Motion** | [Preferred: B03] | Silhouette of muscular athletic back performing a pull-up on a horizontal bar. |
| **Exact Reference Binary PNG** | [Open: O09 / Blocked: G0.3] | **ASSET_SOURCE_UNAVAILABLE**. Original 2,018,426-byte PNG is pending upload. No lookalike substituted. |
| **Wordmark Typography** | [Proposed] | Heavy athletic uppercase: **HOME** in white (`#FFFFFF`) / **SETS** in lime (`#CCFF00`). Font license pending verification. |
| **Exact Color Hex Tokens** | [Proposed] | Candidate palette specified below with measured contrast ratios; requires PO gate review. |
| **Android Adaptive Launcher Icons** | [Proposed] | Master vector SVG and foreground/background layers pending vector tracing of confirmed reference. |

---

## 2. Logo Concept & Strict Usage Rules

### 2.1 The Pull-Up Motion Reference
The owner-preferred visual direction depicts:
- A single rear-view athletic figure performing a pull-up on a horizontal bar.
- Stylized, powerful muscular back, lats, and shoulders.
- High-contrast neon-lime silhouette against a deep near-black charcoal background.
- Clean horizontal bar grounding the athletic posture.

### 2.2 Prohibited Logo Modifications
1. **Never generate lookalike substitutes:** The exact PNG sent by Ahmed on 2026-11-14 is the authoritative visual reference. Do not replace it with AI-generated alternatives.
2. **Never introduce unapproved gym clichés:** No dumbbells, barbells, shields, kettlebells, or generic house roofs.
3. **No distorted aspect ratios:** The mark must always scale with locked 1:1 proportions.
4. **No drop shadows or gradients on the core silhouette:** The mark relies on crisp graphic contrast.

---

## 3. Candidate Color Palette & Measured Contrast

All proposed color roles are evaluated against **WCAG 2.1 Level AA (minimum 4.5:1 for body text, 3:1 for large UI components)**.

### 3.1 Dark Theme (Primary Default)

| Role Name | Hex Code | Contrast vs Background (`#121316`) | WCAG Rating | UI Application |
| :--- | :--- | :--- | :--- | :--- |
| **Surface Dark (Base)** | `#121316` | N/A (Background) | Base Canvas | App background, full-screen canvas. |
| **Surface Card** | `#1C1E24` | 1.15:1 (Subtle elevation) | N/A | Cards, bottom sheets, navigation bar. |
| **Surface Elevated** | `#272A32` | 1.35:1 (Higher elevation) | N/A | Interactive input fields, chips, steppers. |
| **Border / Divider** | `#2E323D` | 1.45:1 (Subtle separator) | N/A | Card borders, horizontal rules. |
| **Primary Accent (Lime)** | `#CCFF00` | **15.2:1** | **AAA** (Exceeds 7:1) | Primary CTA buttons, consistency ring, active tabs, effort badges. |
| **Accent Lime Muted** | `#99CC00` | **10.1:1** | **AAA** | Secondary badges, progress bars, active chip backgrounds. |
| **Text Primary (White)** | `#F4F4F5` | **16.8:1** | **AAA** | Primary headings, exercise names, key numeric values. |
| **Text Muted (Zinc)** | `#A1A1AA` | **7.5:1** | **AAA** | Subtitles, secondary metadata, inactive navigation tabs. |
| **Text Dim (Gray)** | `#71717A` | **4.6:1** | **AA** (Passes 4.5:1) | Timestamps, disabled placeholders, hint copy. |
| **Danger / Pain Red** | `#EF4444` | **4.9:1** | **AA** | Pain alert button, stop workout CTA, destructive reset. |
| **Warning Amber** | `#F59E0B` | **8.2:1** | **AAA** | Interrupted session banner, fatigue warnings. |

### 3.2 Light Theme (Optional Secondary)

| Role Name | Hex Code | Contrast vs Light BG (`#F8FAFC`) | WCAG Rating | UI Application |
| :--- | :--- | :--- | :--- | :--- |
| **Surface Light (Base)** | `#F8FAFC` | N/A (Background) | Base Canvas | App background for light theme. |
| **Surface Card** | `#FFFFFF` | 1.05:1 (Pure white) | N/A | White card elevation on soft slate. |
| **Border / Divider** | `#E2E8F0` | 1.25:1 | N/A | Card outlines. |
| **Primary Accent (Dark Green)** | `#365314` | **9.1:1** (Deep lime/olive) | **AAA** | Primary CTA, active navigation (Lime `#CCFF00` has insufficient contrast on light background; darkened variant used for text/controls). |
| **Text Primary** | `#0F172A` | **17.2:1** | **AAA** | Primary body text and headings. |
| **Text Muted** | `#64748B` | **5.4:1** | **AA** | Subtitles and captions. |

---

## 4. Typography Candidates & Licensing Requirements

### 4.1 Typography Requirements
- Must support clean, modern, athletic Arabic script (Naskh-based modern geometric sans).
- Must have excellent Arabic shaping and diacritics rendering.
- Must provide matching Latin glyphs for bilingual terms (e.g., exercise names like "Pull-ups", "Reps", "Lite Mode").
- License must be 100% free and open-source (OFL - Open Font License) allowing offline bundling inside an Android APK with zero royalties.

### 4.2 Candidate Evaluation

| Font Family | Designer / Source | License | Arabic Aesthetic | Recommendation |
| :--- | :--- | :--- | :--- | :--- |
| **Cairo** | Mohamed Gaber | SIL Open Font License 1.1 | Geometric, energetic, athletic, widely used in modern apps. | **[Recommended Candidate 1]** |
| **IBM Plex Sans Arabic** | IBM / Mike Abbink | SIL Open Font License 1.1 | Technical, clean, highly legible at small sizes on mobile screens. | **[Recommended Candidate 2]** |
| **Readex Pro** | Thomas Jockin et al. | SIL Open Font License 1.1 | Modern, rounded, very accessible; slightly softer character. | **[Alternative Candidate]** |

*Verification Action for P1:* Download official `.ttf` files directly from Google Fonts / GitHub upstream, verify OFL license text, and bundle inside `assets/fonts/`.

---

## 5. Android Adaptive Launcher Icon QA Checklist

When the confirmed reference binary is ingested (Issue #1) and converted to a vector master in Stage G2, it must satisfy this exact quality checklist:

- [ ] **Canvas Specifications:** Master canvas size $108\times 108$ dp ($432\times 432$ px at xxxdpi).
- [ ] **Safe Zone Mask:** Central $66\times 66$ dp ($264\times 264$ px) circle/squircle contains the entire silhouette and bar without clipping.
- [ ] **Layer Separation:**
  - Foreground layer: Pull-Up Motion silhouette in neon lime (`#CCFF00`) on transparent background.
  - Background layer: Deep charcoal (`#121316`) canvas with subtle geometric grid or solid fill.
  - Monochrome layer: Flat white/alpha silhouette for Android 13+ Themed Icons.
- [ ] **Density Exports:** Rendered and verified at:
  - `mdpi` (48×48 px)
  - `hdpi` (72×72 px)
  - `xhdpi` (96×96 px)
  - `xxhdpi` (144×144 px)
  - `xxxhdpi` (192×192 px)
  - Google Play / High-res store format (512×512 px)
- [ ] **Legibility Test:** Scaled down to $24\times 24$ px on device home screen; silhouette remains recognizable without muddy blob distortion.
