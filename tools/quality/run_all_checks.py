#!/usr/bin/env python3
"""
HOMESETS — Master Quality Assurance Runner (Zero External Dependencies)
Executes all validation scripts in tools/quality/ in sequence and reports status.
"""

import sys
import subprocess
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent

SCRIPTS = [
    ("Fixture Schema & Integrity", TOOLS_DIR / "validate_fixtures.py"),
    ("Relative Markdown Links", TOOLS_DIR / "validate_links.py"),
    ("Hygiene & Secret Exposure", TOOLS_DIR / "check_hygiene.py"),
]

def main():
    print("=" * 60)
    print("HOMESETS QUALITY ASSURANCE SUITE")
    print("=" * 60)
    
    failed = []
    
    for name, script_path in SCRIPTS:
        print(f"\n>>> Running: {name} ({script_path.name})")
        res = subprocess.run([sys.executable, str(script_path)], text=True)
        if res.returncode != 0:
            print(f"[ERROR] {name} failed with exit code {res.returncode}")
            failed.append(name)
        else:
            print(f"[OK] {name} passed.")
            
    print("\n" + "=" * 60)
    if failed:
        print(f"FAILED SUITES ({len(failed)}): {', '.join(failed)}")
        sys.exit(1)
    else:
        print("ALL QUALITY SUITES PASSED CLEANLY (3/3)")
        sys.exit(0)

if __name__ == "__main__":
    main()
