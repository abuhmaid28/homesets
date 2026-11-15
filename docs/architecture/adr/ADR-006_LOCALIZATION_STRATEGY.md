# ADR-006: Localization Architecture (Arabic RTL-First & BiDi Isolation)

- **Status:** Recommended (Architecture Baseline)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `DECISION_REGISTER.md` (D15, D16), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

HOMESETS is an Egyptian Arabic RTL-first application with optional English support (D15, D16). Prior visual inspections in Campaign C1-R identified serious Bidirectional text (BiDi) defects when mixing English exercise names or acronyms inside Arabic sentences:
- Broken punctuation wrapping (parentheses flipping to opposite sides).
- Fragmented English words wrapped across multiple lines.
- Unnatural mechanical Arabic translations (`RIR`, `Overload`) causing user confusion.

How should localization and BiDi typography be architected to eliminate rendering glitches and provide an authentic Egyptian Arabic user experience?

---

## Decision Drivers

1. **Native Flutter Localization:** Use standard Flutter `flutter_localizations` (`gen-l10n`) with ARB files (`app_ar.arb`, `app_en.arb`).
2. **BiDi Text Isolation:** Strict layout rules preventing punctuation wrapping when displaying English tokens inside RTL paragraphs.
3. **Egyptian Arabic Tone (D15):** Motivating, warm, culturally authentic Egyptian phrasing without robotic literal translations.
4. **Dynamic Scaling Resilience:** Support 1.5× system font scaling without text overlap or truncation.

---

## Considered Options

- **Option A: Official Flutter `gen-l10n` + Explicit Directional Subtitles (Recommended)**
  - Type-safe `AppLocalizations.of(context)` generated from ARB files.
  - Primary UI text is 100% Arabic. English exercise names are separated into dedicated subtitles wrapped in `<span dir="ltr">` or `Directionality(textDirection: TextDirection.ltr)`.
  - Zero mixed-direction inline parentheses.
- **Option B: Inline Bilingual Strings (`عقلة (Pull-ups)`)**
  - Causes recurrent Blink/WebKit BiDi layout wrapping bugs across Android versions.
- **Option C: Third-Party Localization Packages (EasyLocalization, GetX)**
  - Adds unnecessary external dependencies, slow initialization, and custom file loaders.

---

## Decision Outcome

**Chosen Option:** **Option A: Flutter Official `gen-l10n` with Strict BiDi Separation**.

### Architectural Rules:
1. Primary exercise title must be pure localized Arabic: `عقلة قبضة واسعة`.
2. Secondary English anatomical terminology must reside in a dedicated subordinate widget with explicit `TextDirection.ltr`.
3. Exertion ratings are codified in intuitive Egyptian Arabic:
   - `فاضل طاقة (سهل) 💪`
   - `مظبوط ومثالي 👍`
   - `على الآخر (صعب) 🔥`
4. Formatted numbers and elapsed timers must use `font-variant-numeric: tabular-nums` to prevent horizontal visual jitter.
