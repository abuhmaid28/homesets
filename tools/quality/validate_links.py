#!/usr/bin/env python3
"""
HOMESETS — Relative Markdown Link Validator (Zero External Dependencies)
Verifies that all relative markdown links in docs/ and root point to existing files.
Exits 0 on success, 1 on broken link detection.
"""

import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

# Regex to extract markdown links: [text](path)
LINK_PATTERN = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')

def is_external_or_special(url):
    url_lower = url.strip().lower()
    return (
        url_lower.startswith("http://") or
        url_lower.startswith("https://") or
        url_lower.startswith("mailto:") or
        url_lower.startswith("#") or
        url_lower.startswith("tel:")
    )

def check_file(file_path):
    broken_count = 0
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"[ERROR] Could not read {file_path}: {e}")
        return 1
        
    lines = content.splitlines()
    for line_num, line in enumerate(lines, start=1):
        # Ignore markdown comments or code blocks if simple
        for match in LINK_PATTERN.finditer(line):
            link_target = match.group(2).strip()
            if is_external_or_special(link_target):
                continue
            
            # Strip anchor # if present
            clean_target = link_target.split("#")[0].strip()
            if not clean_target:
                continue
                
            # Strip query params ? if present
            clean_target = clean_target.split("?")[0].strip()
            
            # Resolve relative to the source file directory
            target_path = (file_path.parent / clean_target).resolve()
            
            if not target_path.exists():
                print(f"[BROKEN LINK] {file_path.relative_to(REPO_ROOT)}:{line_num} -> '{link_target}' (Resolved: {target_path})")
                broken_count += 1

    return broken_count

def main():
    print("[CHECK] Scanning markdown files for relative link validity...")
    total_broken = 0
    checked_files = 0
    
    scan_dirs = [REPO_ROOT / "docs", REPO_ROOT]
    
    md_files = []
    for d in scan_dirs:
        if d == REPO_ROOT:
            md_files.extend(list(d.glob("*.md")))
        else:
            md_files.extend(list(d.rglob("*.md")))
            
    # Deduplicate paths
    md_files = sorted(list(set(md_files)))
    
    for f in md_files:
        checked_files += 1
        total_broken += check_file(f)
        
    print(f"\n[SUMMARY] Checked {checked_files} Markdown files. Broken relative links: {total_broken}")
    if total_broken > 0:
        print("[FAIL] Broken internal relative links detected.")
        sys.exit(1)
    else:
        print("[ALL LINKS PASS] All relative document paths exist.")
        sys.exit(0)

if __name__ == "__main__":
    main()
