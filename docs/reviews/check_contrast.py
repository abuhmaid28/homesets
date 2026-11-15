#!/usr/bin/env python3
"""
HOMESETS Design System — W3C WCAG 2.1 Contrast & Relative Luminance Checker
Standard Library Only (Zero External Dependencies)

Authority: docs/DECISION_REGISTER.md (D08, D19, D20), docs/design/BRAND_GUIDELINES_DRAFT.md
Reproducibility: Can be run by any developer/reviewer with standard Python 3.8+
Usage:
    python docs/reviews/check_contrast.py
"""

import sys

def hex_to_rgb(hex_code: str):
    hex_code = hex_code.strip().lstrip('#')
    if len(hex_code) == 3:
        hex_code = ''.join([c*2 for c in hex_code])
    if len(hex_code) != 6:
        raise ValueError(f"Invalid hex color: {hex_code}")
    r = int(hex_code[0:2], 16) / 255.0
    g = int(hex_code[2:4], 16) / 255.0
    b = int(hex_code[4:6], 16) / 255.0
    return r, g, b

def channel_luminance(c: float) -> float:
    if c <= 0.04045:
        return c / 12.92
    else:
        return ((c + 0.055) / 1.055) ** 2.4

def relative_luminance(hex_code: str) -> float:
    r, g, b = hex_to_rgb(hex_code)
    r_lum = channel_luminance(r)
    g_lum = channel_luminance(g)
    b_lum = channel_luminance(b)
    return 0.2126 * r_lum + 0.7152 * g_lum + 0.0722 * b_lum

def contrast_ratio(hex1: str, hex2: str) -> float:
    l1 = relative_luminance(hex1)
    l2 = relative_luminance(hex2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)

# HOMESETS Design Token Palette
PALETTE = {
    # Surfaces
    "Dark Root Background": "#121316",
    "Dark Card/Elevated": "#1C1E24",
    "Dark Input/Sub-surface": "#252830",
    "Light Root Background": "#F8FAFC",
    "Light Card/Elevated": "#FFFFFF",

    # Primary Accent & Functional
    "Performance Lime": "#CCFF00",
    "Lime Dark Contrast (for light bg)": "#365314",
    "Charcoal Deep (Button Text)": "#0F1012",
    "Danger Red (Text/Icon on Dark)": "#EF4444",
    "Danger Red (Filled Button BG)": "#DC2626",
    "Warning Amber": "#F59E0B",
    "Success Green": "#10B981",

    # Typography Tokens
    "Primary Text (Pure White)": "#FFFFFF",
    "Primary Text (Off-white / Slate)": "#F8FAFC",
    "Secondary Text (Zinc Muted)": "#A1A1AA",
    "Accessible Caption Slate": "#9CA3AF",
    "Accessible Tertiary Zinc": "#8E8E93",
    "Decorative / Disabled Only": "#71717A",
    "Light Mode Primary Text": "#0F172A",
    "Light Mode Secondary Text": "#475569",
}

# Evaluated Pairings across the UI
TEST_PAIRS = [
    # Normal Text on Dark Root (#121316) - Requires >= 4.5:1
    ("Primary White", "#FFFFFF", "Dark Root", "#121316", 4.5, "Normal Text (Primary)"),
    ("Primary Off-White", "#F8FAFC", "Dark Root", "#121316", 4.5, "Normal Text (Primary Body)"),
    ("Secondary Muted", "#A1A1AA", "Dark Root", "#121316", 4.5, "Normal Text (Secondary Meta)"),
    ("Caption Slate", "#9CA3AF", "Dark Root", "#121316", 4.5, "Normal Text (Caption/Labels)"),
    ("Tertiary Zinc", "#8E8E93", "Dark Root", "#121316", 4.5, "Normal Text (Tertiary/Subtle)"),
    ("Performance Lime", "#CCFF00", "Dark Root", "#121316", 3.0, "UI Accent / Large Heading"),
    ("Danger Red Text", "#EF4444", "Dark Root", "#121316", 4.5, "Stop/Pain Alert Text on Dark Root"),

    # Normal Text on Dark Card (#1C1E24) - Requires >= 4.5:1
    ("Primary White", "#FFFFFF", "Dark Card", "#1C1E24", 4.5, "Card Primary Title"),
    ("Secondary Muted", "#A1A1AA", "Dark Card", "#1C1E24", 4.5, "Card Secondary Subtitle"),
    ("Caption Slate", "#9CA3AF", "Dark Card", "#1C1E24", 4.5, "Card Caption/Meta"),
    ("Tertiary Zinc", "#8E8E93", "Dark Card", "#1C1E24", 4.5, "Card Tertiary Hint"),

    # Buttons & Interactive States
    ("Charcoal Deep Text", "#0F1012", "Performance Lime Button", "#CCFF00", 4.5, "Primary CTA Button Text"),
    ("Primary White Text", "#FFFFFF", "Danger Red Filled BG", "#DC2626", 4.5, "Destructive/Stop Filled Button"),

    # Non-Text UI Controls / Borders (Requires >= 3.0:1)
    ("Disabled/Border Zinc", "#71717A", "Dark Root", "#121316", 3.0, "Inactive Border / Disabled Non-Text"),
    ("Disabled/Border Zinc", "#71717A", "Dark Card", "#1C1E24", 3.0, "Card Inactive Border"),

    # Light Mode Surface Pairings
    ("Light Primary Text", "#0F172A", "Light Root", "#F8FAFC", 4.5, "Light Mode Primary"),
    ("Light Secondary Text", "#475569", "Light Root", "#F8FAFC", 4.5, "Light Mode Secondary"),
    ("Lime Dark Contrast", "#365314", "Light Root", "#F8FAFC", 4.5, "Light Mode Brand Accent"),
]

def main():
    print("=" * 80)
    print("HOMESETS WCAG 2.1 Color Contrast Audit (Automated Verification)")
    print("=" * 80)
    print(f"{'Foreground':<24} {'Background':<24} {'Ratio':<10} {'Req':<6} {'Status':<8} {'Usage Context'}")
    print("-" * 80)

    failures = 0
    for fg_name, fg_hex, bg_name, bg_hex, min_ratio, context in TEST_PAIRS:
        ratio = contrast_ratio(fg_hex, bg_hex)
        passed = ratio >= min_ratio
        status = "PASS" if passed else "FAIL"
        if not passed:
            failures += 1
        print(f"{fg_name + ' (' + fg_hex + ')':<24} {bg_name + ' (' + bg_hex + ')':<24} {ratio:>6.2f}:1   {min_ratio:>4.1f}:1 {status:<8} {context}")

    print("-" * 80)

    # Explicit negative check: ensure #71717A is documented as failing normal text (4.5:1)
    ratio_71717a = contrast_ratio("#71717A", "#121316")
    print(f"\n[Validation Guardrail 1] #71717A on #121316 = {ratio_71717a:.2f}:1")
    if ratio_71717a < 4.5:
        print("  -> Confirmed: #71717A FAILS normal text (4.5:1). Correctly restricted to non-text (>= 3.0:1).")
    else:
        print("  -> Unexpected: #71717A should fail 4.5:1 normal text threshold.")
        failures += 1

    # Explicit check for Danger Red on White
    ratio_ef4444_white = contrast_ratio("#EF4444", "#FFFFFF")
    print(f"[Validation Guardrail 2] #EF4444 with White Text = {ratio_ef4444_white:.2f}:1")
    if ratio_ef4444_white < 4.5:
        print("  -> Confirmed: #EF4444 FAILS normal text on white. Filled stop button uses #DC2626 (4.83:1, PASS).")
    else:
        failures += 1

    print("=" * 80)
    if failures == 0:
        print("ALL VERIFIED TOKEN PAIRINGS PASS WCAG REQUIREMENTS.")
        return 0
    else:
        print(f"AUDIT FAILED WITH {failures} UNRESOLVED CONTRAST ISSUES.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
