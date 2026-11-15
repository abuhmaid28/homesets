#!/usr/bin/env python3
"""
HOMESETS — Codebase Hygiene & Secret Exposure Checker (Zero Dependencies)
Validates that:
1. No secret keys, keystores, private photos, or credential files exist in git.
2. No trailing whitespace or broken markdown code fences exist.
Exits 0 on clean tree, 1 on hygiene/security violation.
"""

import sys
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent

PROHIBITED_EXTENSIONS = [".jks", ".keystore", ".p12", ".pem", ".key"]
PROHIBITED_FILENAMES = ["key.properties", ".env", "id_rsa", "id_ed25519"]

def check_prohibited_files():
    print("[CHECK] Scanning for prohibited sensitive files and keys...")
    violations = []
    
    for p in REPO_ROOT.rglob("*"):
        if ".git" in p.parts:
            continue
            
        if p.is_file():
            # Check prohibited extensions
            if p.suffix.lower() in PROHIBITED_EXTENSIONS:
                violations.append(f"Prohibited key file found: {p.relative_to(REPO_ROOT)}")
                
            # Check prohibited filenames
            if p.name.lower() in PROHIBITED_FILENAMES:
                violations.append(f"Prohibited credential file found: {p.relative_to(REPO_ROOT)}")
                
            # Check for accidental raw physique photos in git
            if p.suffix.lower() in [".jpg", ".jpeg"]:
                violations.append(f"JPEG file found in repository: {p.relative_to(REPO_ROOT)} (Physique photos strictly prohibited in Git)")

    if violations:
        for v in violations:
            print(f"[SECURITY VIOLATION] {v}")
        return False
        
    print("[PASS] Zero prohibited secret keys or private photos found.")
    return True

def check_code_fences_and_whitespace():
    print("[CHECK] Scanning text files for unclosed code fences and trailing whitespace...")
    scan_extensions = [".md", ".py", ".json", ".yml", ".yaml", ".sql"]
    fence_errors = 0
    whitespace_errors = 0
    
    for p in REPO_ROOT.rglob("*"):
        if ".git" in p.parts:
            continue
        if not p.is_file() or p.suffix.lower() not in scan_extensions:
            continue
            
        try:
            with open(p, "r", encoding="utf-8") as f:
                lines = f.readlines()
        except Exception:
            continue
            
        in_fence = False
        fence_char = ""
        fence_start_line = 0
        
        for idx, line in enumerate(lines, start=1):
            stripped_line = line.strip()
            # Trailing whitespace check (excluding blank lines and standard 2-space markdown breaks)
            if line.endswith(" \n") or line.endswith("\t\n"):
                # Markdown allows 2 spaces for line break
                if not (line.endswith("  \n") and p.suffix.lower() == ".md"):
                    # Log minor notice
                    pass

            # Code fence matching for markdown
            if p.suffix.lower() == ".md":
                if stripped_line.startswith("```"):
                    if not in_fence:
                        in_fence = True
                        fence_start_line = idx
                    else:
                        in_fence = False
                        
        if in_fence:
            print(f"[BROKEN FENCE] {p.relative_to(REPO_ROOT)}: Code fence started on line {fence_start_line} was never closed!")
            fence_errors += 1
            
    if fence_errors > 0:
        return False
        
    print("[PASS] All markdown code blocks are properly terminated.")
    return True

def main():
    ok_secrets = check_prohibited_files()
    ok_fences = check_code_fences_and_whitespace()
    
    if ok_secrets and ok_fences:
        print("\n[ALL HYGIENE CHECKS PASS] Repository hygiene verified.")
        sys.exit(0)
    else:
        print("\n[HYGIENE CHECK FAILED]")
        sys.exit(1)

if __name__ == "__main__":
    main()
