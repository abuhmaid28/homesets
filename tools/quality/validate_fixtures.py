#!/usr/bin/env python3
"""
HOMESETS — Semantic, Type-Safe Relational Fixture Validator (Zero External Dependencies)
Validates engine_scenarios.json and exercise_catalog.json against architectural rules:
1. Strict schema & data type validation.
2. Semantic input/output uniqueness (no duplicate scenario vectors).
3. Permitted enum actions and movement patterns.
4. Relational cross-referencing between scenario exercise references and catalog IDs.
5. Bidirectional alternative validity in the exercise catalog.

Exits 0 on success, 1 on validation error.
"""

import sys
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_SCENARIOS_PATH = REPO_ROOT / "docs" / "domain" / "fixtures" / "engine_scenarios.json"
DEFAULT_CATALOG_PATH = REPO_ROOT / "docs" / "domain" / "fixtures" / "exercise_catalog.json"

REQUIRED_SCENARIO_FIELDS = [
    "id", "category", "description", "input_state",
    "expected_output", "is_negative_case", "policy_tag"
]

VALID_CATEGORIES = {
    "PROGRESSION_DOUBLE_BODYWEIGHT",
    "PROGRESSION_CADENCE_PAUSE",
    "PROGRESSION_BAND_ASSISTANCE",
    "PROGRESSION_BAND_RESISTANCE",
    "SAFETY_PAIN_STOP_PRECEDENCE",
    "SCHEDULING_RECOVERY_SPACING",
    "SCHEDULING_ABSENCE_DELOAD",
    "LITE_MODE_ADAPTATION",
    "EQUIPMENT_ABSENCE_FALLBACKS",
    "SHIFT_WORK_TIME_BOUNDARIES"
}

VALID_ACTIONS = {
    "ADAPTATION_REENTRY_DELOAD",
    "ADVANCE_BRACKET",
    "ALLOW_SESSION",
    "APPLY_TEMPO",
    "CADENCE_PAUSE_OVERLOAD",
    "EXPAND_BRACKET",
    "FILTER_PROVOCATIVE_EXERCISES",
    "HOLD_ASSISTANCE",
    "HOLD_LOAD",
    "INCREASE_RESISTANCE",
    "INDEPENDENT_EXERCISE_TRACKING",
    "LEVERAGE_ADVANCE",
    "LEVERAGE_REGRESS",
    "LIGHT_REENTRY_DELOAD",
    "NORMAL_ROTATION_RESUME",
    "PRESCRIBE_ROTATION",
    "PRUNE_TO_ESSENTIALS",
    "REDUCE_ASSISTANCE",
    "ROTATE_TO_UNFATIGUED_GROUP",
    "SAFETY_PROMPT",
    "STEP_BACK_BRACKET",
    "SUBSTITUTE_ACCORDING_TO_HARDWARE",
    "TERMINATE_SESSION_SAFELY",
    "UNILATERAL_OVERLOAD"
}

REQUIRED_EXERCISE_FIELDS = [
    "id", "slug", "name_ar", "name_en", "pattern",
    "primary_muscles", "required_equipment",
    "supports_band_assistance", "supports_band_resistance",
    "skill_prerequisite_reps", "technique_cues_ar", "technique_cues_en"
]

VALID_PATTERNS = {
    "VERTICAL_PULL",
    "HORIZONTAL_PULL",
    "HORIZONTAL_PUSH",
    "QUAD_DOMINANT",
    "ISOLATION_ARM"
}

VALID_EQUIPMENT = {
    "pull_up_bar",
    "resistance_bands",
    "bodyweight"
}

EXERCISE_REF_KEYS = [
    "exercise", "candidate_exercise", "next_exercise",
    "prescribed_exercise", "excluded_exercise", "active_exercise"
]

SCENARIO_ID_REGEX = re.compile(r"^SCEN-\d{3,}$")
EXERCISE_ID_REGEX = re.compile(r"^[a-z0-9_]+$")
EXERCISE_SLUG_REGEX = re.compile(r"^[a-z0-9-]+$")


def validate_catalog_data(catalog_data):
    """Validates exercise catalog data structure and internal integrity."""
    if not isinstance(catalog_data, dict):
        return False, "Catalog data must be a JSON object"

    exercises = catalog_data.get("exercises")
    if not isinstance(exercises, list) or len(exercises) == 0:
        return False, "Catalog must contain a non-empty 'exercises' array"

    seen_ids = set()
    seen_slugs = set()

    for idx, ex in enumerate(exercises):
        if not isinstance(ex, dict):
            return False, f"Exercise #{idx} is not an object"

        for field in REQUIRED_EXERCISE_FIELDS:
            if field not in ex:
                return False, f"Exercise #{idx} missing required field '{field}'"

        ex_id = ex["id"]
        if not isinstance(ex_id, str) or not EXERCISE_ID_REGEX.match(ex_id):
            return False, f"Exercise #{idx} invalid id: '{ex_id}'"
        if ex_id in seen_ids:
            return False, f"Duplicate exercise ID: '{ex_id}'"
        seen_ids.add(ex_id)

        slug = ex["slug"]
        if not isinstance(slug, str) or not EXERCISE_SLUG_REGEX.match(slug):
            return False, f"Exercise '{ex_id}' invalid slug: '{slug}'"
        if slug in seen_slugs:
            return False, f"Duplicate exercise slug: '{slug}'"
        seen_slugs.add(slug)

        pattern = ex["pattern"]
        if pattern not in VALID_PATTERNS:
            return False, f"Exercise '{ex_id}' invalid pattern: '{pattern}'"

        primary = ex["primary_muscles"]
        if not isinstance(primary, list) or len(primary) == 0:
            return False, f"Exercise '{ex_id}' primary_muscles must be a non-empty list"

        equipment = ex["required_equipment"]
        if not isinstance(equipment, list) or len(equipment) == 0:
            return False, f"Exercise '{ex_id}' required_equipment must be a non-empty list"
        for eq in equipment:
            if eq not in VALID_EQUIPMENT:
                return False, f"Exercise '{ex_id}' unapproved equipment: '{eq}'"

        if not isinstance(ex["supports_band_assistance"], bool):
            return False, f"Exercise '{ex_id}' supports_band_assistance must be bool"
        if not isinstance(ex["supports_band_resistance"], bool):
            return False, f"Exercise '{ex_id}' supports_band_resistance must be bool"

        reps = ex["skill_prerequisite_reps"]
        if not isinstance(reps, int) or reps < 0:
            return False, f"Exercise '{ex_id}' skill_prerequisite_reps must be integer >= 0"

    # Bidirectional alternative check
    for ex in exercises:
        alt_id = ex.get("unprovocative_alternative_id")
        if alt_id and alt_id not in seen_ids:
            return False, f"Exercise '{ex['id']}' references non-existent unprovocative_alternative_id: '{alt_id}'"

    return True, f"Exercise catalog valid ({len(exercises)} movements)"


def validate_scenarios_data(scenarios_data, valid_exercise_ids=None):
    """Validates engine scenarios data structure, types, semantics and relational links."""
    if not isinstance(scenarios_data, dict):
        return False, "Scenarios data must be a JSON object"

    scenarios = scenarios_data.get("scenarios")
    if not isinstance(scenarios, list):
        return False, "Scenarios must contain a 'scenarios' list"

    if len(scenarios) < 100:
        return False, f"Expected at least 100 scenarios, found {len(scenarios)}"

    seen_ids = set()
    seen_vectors = {}
    pos_count = 0
    neg_count = 0

    for idx, s in enumerate(scenarios):
        if not isinstance(s, dict):
            return False, f"Scenario #{idx} is not an object"

        for field in REQUIRED_SCENARIO_FIELDS:
            if field not in s:
                return False, f"Scenario #{idx} missing required field '{field}'"

        s_id = s["id"]
        if not isinstance(s_id, str) or not SCENARIO_ID_REGEX.match(s_id):
            return False, f"Scenario #{idx} invalid ID format: '{s_id}'"
        if s_id in seen_ids:
            return False, f"Duplicate scenario ID: '{s_id}'"
        seen_ids.add(s_id)

        cat = s["category"]
        if cat not in VALID_CATEGORIES:
            return False, f"Scenario '{s_id}' invalid category: '{cat}'"

        desc = s["description"]
        if not isinstance(desc, str) or not desc.strip():
            return False, f"Scenario '{s_id}' description must be a non-empty string"

        input_state = s["input_state"]
        if not isinstance(input_state, dict) or len(input_state) == 0:
            return False, f"Scenario '{s_id}' input_state must be a non-empty object"

        expected_output = s["expected_output"]
        if not isinstance(expected_output, dict) or len(expected_output) == 0:
            return False, f"Scenario '{s_id}' expected_output must be a non-empty object"

        if not isinstance(s["is_negative_case"], bool):
            return False, f"Scenario '{s_id}' is_negative_case must be boolean"

        policy = s["policy_tag"]
        if not isinstance(policy, str) or not policy.strip():
            return False, f"Scenario '{s_id}' policy_tag must be a non-empty string"

        if s["is_negative_case"]:
            neg_count += 1
        else:
            pos_count += 1

        # Semantic uniqueness check: no identical input+output vector
        vector_key = (
            json.dumps(input_state, sort_keys=True),
            json.dumps(expected_output, sort_keys=True)
        )
        if vector_key in seen_vectors:
            prev_id = seen_vectors[vector_key]
            return False, f"Duplicate scenario vector detected: '{s_id}' has identical input/output to '{prev_id}'"
        seen_vectors[vector_key] = s_id

        # Action enum validation
        if "action" in expected_output:
            action = expected_output["action"]
            if action not in VALID_ACTIONS:
                return False, f"Scenario '{s_id}' invalid action enum: '{action}'"
        elif "expected_behavior" not in expected_output:
            return False, f"Scenario '{s_id}' expected_output missing 'action' or 'expected_behavior'"

        # Referential integrity check
        if valid_exercise_ids is not None:
            for d in (input_state, expected_output):
                for k in EXERCISE_REF_KEYS:
                    if k in d:
                        val = d[k]
                        if isinstance(val, str) and val not in valid_exercise_ids:
                            return False, f"Scenario '{s_id}' references unknown exercise '{val}' in key '{k}'"

    if pos_count == 0 or neg_count == 0:
        return False, f"Scenarios must contain both positive and negative cases (pos={pos_count}, neg={neg_count})"

    return True, f"Scenarios valid ({len(scenarios)} total: {pos_count} positive, {neg_count} negative)"


def validate_fixtures(scenarios_path=DEFAULT_SCENARIOS_PATH, catalog_path=DEFAULT_CATALOG_PATH):
    """Loads and validates both fixtures with relational cross-referencing."""
    print(f"[CHECK] Validating catalog: {catalog_path}")
    if not catalog_path.exists():
        print(f"[FAIL] Catalog not found: {catalog_path}")
        return False

    try:
        with open(catalog_path, "r", encoding="utf-8") as f:
            cat_data = json.load(f)
    except Exception as e:
        print(f"[FAIL] Invalid JSON in catalog: {e}")
        return False

    cat_ok, cat_msg = validate_catalog_data(cat_data)
    if not cat_ok:
        print(f"[FAIL] {cat_msg}")
        return False
    print(f"[PASS] {cat_msg}")

    valid_ex_ids = {e["id"] for e in cat_data["exercises"]}

    print(f"[CHECK] Validating scenarios: {scenarios_path}")
    if not scenarios_path.exists():
        print(f"[FAIL] Scenarios not found: {scenarios_path}")
        return False

    try:
        with open(scenarios_path, "r", encoding="utf-8") as f:
            scen_data = json.load(f)
    except Exception as e:
        print(f"[FAIL] Invalid JSON in scenarios: {e}")
        return False

    scen_ok, scen_msg = validate_scenarios_data(scen_data, valid_exercise_ids=valid_ex_ids)
    if not scen_ok:
        print(f"[FAIL] {scen_msg}")
        return False
    print(f"[PASS] {scen_msg}")

    return True


def main():
    ok = validate_fixtures()
    if ok:
        print("\n[ALL FIXTURES PASS] Semantic integrity & referential consistency verified.")
        sys.exit(0)
    else:
        print("\n[FIXTURE VALIDATION FAILED]")
        sys.exit(1)


if __name__ == "__main__":
    main()
