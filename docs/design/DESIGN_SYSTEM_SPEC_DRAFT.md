# HOMESETS — Design System Specification Draft (Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G4 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)

---

## 1. Architectural Strategy: Flutter ThemeExtensions

To prevent hard-coded colors, padding, and font styles across UI widgets, all design tokens will be implemented as typed **Flutter `ThemeExtension` classes** (`HomesetsColors`, `HomesetsTypography`, `HomesetsSpacing`).

```dart
// Conceptual architectural pattern for Milestone P1:
@immutable
class HomesetsColors extends ThemeExtension<HomesetsColors> {
  final Color bgDark;           // #121316 (Base canvas)
  final Color cardDark;         // #1C1E24 (Card surface)
  final Color elevatedDark;     // #22252E (Input / stepper surface)
  final Color accentLime;       // #CCFF00 (Primary CTA & highlights, 15.81:1 on bg)
  final Color accentLimeDim;    // #99CC00 (Secondary badges, 9.72:1 on bg)
  final Color textPrimary;      // #F4F4F5 (Primary text, 16.90:1 on bg)
  final Color textSecondary;    // #A1A1AA (Secondary text, 7.25:1 on bg, 6.50:1 on card)
  final Color textTertiary;     // #8E8E93 (Accessible tertiary text, 5.70:1 on bg, 5.11:1 on card, PASS AA)
  final Color controlDisabled;  // #71717A (Non-text only: borders/disabled outlines, 3.84:1, PASS non-text AA >=3:1)
  final Color danger;           // #EF4444 (Pain stop text/icon / error borders, 4.94:1 on bg)
  final Color dangerFilled;     // #DC2626 (Solid filled button bg with #FFFFFF text, 4.83:1 PASS AA)
  final Color warning;          // #F59E0B (Recovery alerts / interrupted session)

  const HomesetsColors({ ... });
}
```

---

## 2. Spacing & Elevation System (4dp Grid)

All layout dimensions, paddings, and margins snap to a base **4dp geometric grid**:

| Token Name | Value | Intended Usage |
| :--- | :--- | :--- |
| `space-1` | 4 dp | Tight micro-spacing, badge padding, icon gap. |
| `space-2` | 8 dp | Chip spacing, list item internal padding. |
| `space-3` | 12 dp | Input field vertical padding, small card gap. |
| `space-4` | 16 dp | Standard screen edge margin, card internal padding. |
| `space-5` | 20 dp | Large card internal padding, bottom sheet top padding. |
| `space-6` | 24 dp | Section separation, header bottom spacing. |
| `space-8` | 32 dp | Major section dividers, modal top margins. |
| `space-12`| 48 dp | Workout player bottom thumb-zone clearance. |

### Corner Radii
- `radius-sm`: 8 dp (Badges, tags, small chips).
- `radius-md`: 12 dp (Standard buttons, feedback pills, text fields).
- `radius-lg`: 16 dp (Standard cards, alert banners).
- `radius-xl`: 20–24 dp (Primary workout cards, rest timer drawer).
- `radius-pill`: 999 dp (Circular buttons, floating status indicators).

---

## 3. Typographic Hierarchy (Scalable sp)

Typography is defined in scalable pixels (`sp`) supporting Android system text scaling up to **1.5× without layout clipping or text truncation**.

| Role | Font Size / Line Height | Weight | Application |
| :--- | :--- | :--- | :--- |
| **Display Hero** | 32 sp / 40 sp | Bold (800) | Rest timer countdown, primary weight numbers. |
| **Headline Large**| 24 sp / 32 sp | Bold (800) | Current exercise name in Workout Player. |
| **Headline Medium**| 20 sp / 28 sp | Bold (700) | Screen titles (Today, Progress, Settings). |
| **Title Medium** | 16 sp / 24 sp | Semi-Bold (600) | Card headings, section labels. |
| **Body Large** | 16 sp / 24 sp | Regular (400) | General instructional copy, explanations. |
| **Body Medium** | 14 sp / 20 sp | Regular (400) | Exercise secondary cues, checklist items. |
| **Label Large** | 14 sp / 20 sp | Bold (700) | Primary button labels (e.g. "تسجيل المجموعة"). |
| **Label Small** | 11 sp / 16 sp | Medium (500) | Bottom navigation labels, timestamp captions. |

---

## 4. Interactive Component Specifications

### 4.1 Primary CTA Button (`HomesetsPrimaryButton`)
- **Height:** 56–60 dp (Oversized for effortless thumb access).
- **Background:** Primary Lime (`#CCFF00`), Text: Deep Black (`#0B0C0E`).
- **Corner Radius:** 16–20 dp.
- **States:**
  - *Default:* Full saturation, elevation shadow `0 8px 20px rgba(204, 255, 0, 0.2)`.
  - *Pressed:* Scale transform $0.98\times$, slight opacity drop ($0.9$).
  - *Disabled:* Background `#272A32`, Text `#71717A`, zero shadow.
  - *Loading:* Circular spinner in `#0B0C0E` centered; label hidden.

### 4.2 Rep Stepper Widget (`HomesetsRepStepper`)
- **Purpose:** Fast single-hand adjustment of completed reps during a set.
- **Layout:** Horizontal layout: `[-]` button (52×52 dp) $\longleftrightarrow$ Big Numeric Display $\longleftrightarrow$ `[+]` button (52×52 dp).
- **Behavior:**
  - Single tap adjusts reps by $\pm 1$.
  - Long press accelerates increment/decrement.
  - Number is centered in display size (32 sp, bold lime).

### 4.3 Rest Timer Modal / Drawer (`HomesetsRestDrawer`)
- **Purpose:** Immediate visual and audio/haptic feedback between sets.
- **Components:**
  - Circular animated countdown ring ($100\times 100$ dp).
  - Digital clock display (`MM:SS`) in centered hero typography.
  - Effort rating pills (`Easy` / `Right` / `Hard`) directly accessible above control buttons.
  - Quick action buttons: `+30 ثانية (+30s)` and `تخطي الراحة (Skip)`.
- **Haptic Feedback:**
  - 10-second countdown tick (light haptic pulse).
  - 0-second completion (distinct double vibration pattern).

### 4.4 Photo Comparison Slider (`HomesetsPhotoCompareSlider`)
- **Purpose:** Side-by-side split screen comparing progress photos across time.
- **Interaction:**
  - Horizontal drag gesture splits Photo A (Before) and Photo B (After).
  - Central dividing line in neon lime (`#CCFF00`) with circular thumb handle.
  - Date and body weight badges pinned to lower corners.

---

## 5. Accessibility, Semantics & RTL Mirroring Rules

### 5.1 Touch Target Compliance
- All tappable icons and secondary buttons must have a minimum bounding box of **$48\times 48$ dp**.
- Primary workout logging buttons must have a minimum bounding box of **$56\times 56$ dp**.

### 5.2 RTL Mirroring Rules for Arabic
- **Mirrored Elements:**
  - Horizontal screen transitions (sliding in from the left instead of right).
  - Navigation back arrows (`Icons.arrow_back` flipped to point right).
  - Consistency ring rotation and progress bar fills (fill from right to left).
  - Card alignments (titles and icons align right).
- **Non-Mirrored (Preserved LTR) Elements:**
  - Numerical inputs, clock displays, and countdown timers (`01:30`).
  - English exercise subtitles (`Pull-ups`, `Band Row`).
  - Progress photo comparison slider (left/right drag remains neutral).

### 5.3 Motion & Transitions
- Micro-interactions must be fast and crisp (maximum 200 ms duration, `Curves.easeInOutCubic`).
- Workout flow must never feel delayed by gratuitous animation.
- Supports system-level "Remove animations" accessibility preference.

### 5.4 Responsive Viewport Adaptation & Design Artifact Status
- **Fluid Vertical Layouts:** Screen designs must never assume a fixed 844 dp height. All viewports (from compact 360×780 dp to large 412×915 dp) must scroll smoothly, respecting Android system gesture bars and camera cutouts (`SafeArea`).
- **Static Visual Prototypes:** Wireframe and exploration HTML files are **static design prototypes** designed for visual review and headless screenshot generation; they contain zero JavaScript or simulated application logic. All vector silhouettes shown are abstract placeholders, not final logo masters.
