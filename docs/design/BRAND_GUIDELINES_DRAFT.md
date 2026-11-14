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

## 3. Candidate Color Palette & Measured Contrast (WCAG 2.1 Audit)

All proposed color roles are mathematically verified against **WCAG 2.1 Level AA (minimum 4.5:1 for normal body text, 3.0:1 for large UI components $\ge 18$pt or $\ge 14$pt bold)** and **Level AAA (7.0:1 normal, 4.5:1 large)**.

### 3.1 Mathematical Contrast Formula & Verification Method
Relative luminance $L$ is computed per W3C specification:
For each 8-bit channel $C \in \{R, G, B\}$, $C_{\text{srgb}} = C / 255.0$:
$$C_{\text{linear}} = \begin{cases} \frac{C_{\text{srgb}}}{12.92} & \text{if } C_{\text{srgb}} \le 0.04045 \\ \left(\frac{C_{\text{srgb}} + 0.055}{1.055}\right)^{2.4} & \text{if } C_{\text{srgb}} > 0.04045 \end{cases}$$
$$L = 0.2126 \cdot R_{\text{linear}} + 0.7152 \cdot G_{\text{linear}} + 0.0722 \cdot B_{\text{linear}}$$
$$\text{Contrast Ratio} = \frac{\max(L_1, L_2) + 0.05}{\min(L_1, L_2) + 0.05}$$

### 3.2 Dark Theme (Primary Default) — Multi-Surface Matrix

| Role Name | Hex Code | Canvas Surface (`#121316`) | Card Surface (`#1C1E24`) | Elevated Surface (`#22252E`) | Compliance Level | UI Application & Restrictions |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Surface Dark (Base)** | `#121316` | Base Canvas | N/A | N/A | Base | Full-screen background canvas. |
| **Surface Card** | `#1C1E24` | 1.15:1 | Base Card | N/A | Base | Workout cards, navigation drawer, sheets. |
| **Surface Elevated** | `#22252E` | 1.35:1 | 1.17:1 | Base Elevated | Base | Input fields, active chips, stepper box. |
| **Primary Accent (Lime)** | `#CCFF00` | **15.81:1** | **14.18:1** | **13.02:1** | **AAA** (All) | Primary CTA buttons, consistency ring, active tabs. |
| **Accent Lime Muted** | `#99CC00` | **9.72:1** | **8.72:1** | **8.01:1** | **AAA** (All) | Secondary badges, progress bars, active chip borders. |
| **Text Primary (White)** | `#F4F4F5` | **16.90:1** | **15.16:1** | **13.92:1** | **AAA** (All) | Primary headings, exercise names, key numbers. |
| **Text Muted (Zinc-400)** | `#A1A1AA` | **7.25:1** | **6.50:1** | **5.97:1** | **AAA** / **AA** | Subtitles, secondary metadata, inactive navigation tabs. |
| **Text Tertiary (Accessible)**| `#8E8E93` | **5.70:1** | **5.11:1** | **4.69:1** | **AA** (All $\ge 4.5:1$) | Caption text, timestamps, unit labels (`كجم`, `تكرار`). |
| **Control Disabled (Non-Text)**| `#71717A` | **3.84:1 (FAIL text)**| **3.45:1 (FAIL text)**| **3.17:1 (FAIL text)**| **Non-Text AA** ($\ge 3:1$) | **RESTRICTED TO NON-TEXT ONLY.** Disabled button outlines, inactive dividers. **Must NOT be used for readable text.** |
| **Danger / Pain Red** | `#EF4444` | **4.94:1 (AA text)** | **4.43:1 (AA large)** | **4.07:1 (AA large)** | **AA Large** | Pain stop CTA buttons, warning dialog borders. For small text on cards, use `#F87171` (6.57:1). |
| **Warning Amber** | `#F59E0B` | **8.65:1** | **7.76:1** | **7.13:1** | **AAA** (All) | Interrupted session recovery banner, fatigue alerts. |
| **Black CTA Text** | `#0B0C0E` | N/A | N/A | N/A | **16.65:1 (AAA)** | Text on Lime CTA button (`#CCFF00`). |

### 3.3 Light Theme (Optional Secondary)

| Role Name | Hex Code | Light Root (`#F8FAFC`) | Light Card (`#FFFFFF`) | Compliance Level | UI Application |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Surface Light (Base)** | `#F8FAFC` | Base Canvas | N/A | Base | App background for light theme. |
| **Surface Card** | `#FFFFFF` | 1.05:1 | Base Card | Base | White card elevation on soft slate. |
| **Primary Accent (Dark Green)**| `#365314`| **8.35:1** | **8.73:1** | **AAA** | Primary CTA, active navigation. |
| **Text Primary** | `#0F172A` | **17.06:1** | **17.85:1** | **AAA** | Primary body text and headings. |
| **Text Muted** | `#64748B` | **4.55:1** | **4.76:1** | **AA** (Normal) | Subtitles and captions. |

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
