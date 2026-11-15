#!/usr/bin/env python3
"""
HOMESETS — Fixture Schema & Integrity Validator (Zero External Dependencies)
Validates engine_scenarios.json and exercise_catalog.json against architectural rules.
Exits 0 on success, 1 on validation error.
"""

import sys
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
SCENARIOS_PATH = REPO_ROOT / "docs" / "domain" / "fixtures" / "engine_scenarios.json"
CATALOG_PATH = REPO_ROOT / "docs" / "domain" / "fixtures" / "exercise_catalog.json"

REQUIRED_SCENARIO_FIELDS = ["id", "category", "description", "input_state", "expected_output", "is_negative_case", "policy_tag"]
REQUIRED_EXERCISE_FIELDS = ["id", "slug", "name_ar", "name_en", "pattern", "primary_muscles", "required_equipment"]

def validate_scenarios():
    print(f"[CHECK] Validating {SCENARIOS_PATH.relative_to(REPO_ROOT)}...")
    if not SCENARIOS_PATH.exists():
        print(f"[FAIL] Scenarios file not found: {SCENARIOS_PATH}")
        return False
    
    try:
        with open(SCENARIOS_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"[FAIL] Invalid JSON in scenarios file: {e}")
        return False
    
    scenarios = data.get("scenarios", [])
    if len(scenarios) < 100:
        print(f"[FAIL] Expected at least 100 scenarios, found {len(scenarios)}")
        return False
    
    seen_ids = set()
    pos_count = 0
    neg_count = 0
    
    for idx, s in enumerate(scenarios):
        for field in REQUIRED_SCENARIO_FIELDS:
            if field not in s:
                print(f"[FAIL] Scenario #{idx} missing required field '{field}'")
                return False
        
        s_id = s["id"]
        if s_id in seen_ids:
            print(f"[FAIL] Duplicate scenario ID detected: {s_id}")
            return False
        seen_ids.add(s_id)
        
        if s["is_negative_case"]:
            neg_count += 1
        else:
            pos_count += 1

    if pos_count == 0 or neg_count == 0:
        print(f"[FAIL] Expected mix of positive and negative cases (pos={pos_count}, neg={neg_count})")
        return False
        
    print(f"[PASS] Scenarios validated: {len(scenarios)} total ({pos_count} positive, {neg_count} negative/stress cases).")
    return True

def validate_catalog():
    print(f"[CHECK] Validating {CATALOG_PATH.relative_to(REPO_ROOT)}...")
    if not CATALOG_PATH.exists():
        print(f"[FAIL] Exercise catalog file not found: {CATALOG_PATH}")
        return False
        
    try:
        with open(CATALOG_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as e:
        print(f"[FAIL] Invalid JSON in catalog file: {e}")
        return False
        
    exercises = data.get("exercises", [])
    if not exercises:
        print("[FAIL] Exercise catalog is empty")
        return False
        
    seen_slugs = set()
    for idx, ex in enumerate(exercises):
        for field in REQUIRED_EXERCISE_FIELDS:
            if field not in ex:
                print(f"[FAIL] Exercise #{idx} missing required field '{field}'")
                return False
        
        slug = ex["slug"]
        if slug in seen_slugs:
            print(f"[FAIL] Duplicate exercise slug detected: {slug}")
            return False
        seen_slugs.add(slug)
        
    print(f"[PASS] Exercise catalog validated: {len(exercises)} valid movement definitions.")
    return True

def main():
    ok_scen = validate_scenarios()
    ok_cat = validate_catalog()
    
    if ok_scen and ok_cat:
        print("\n[ALL FIXTURES PASS] Data integrity verified.")
        sys.exit(0)
    else:
        print("\n[FIXTURE VALIDATION FAILED]")
        sys.exit(1)

if __name__ == "__main__":
    main()
