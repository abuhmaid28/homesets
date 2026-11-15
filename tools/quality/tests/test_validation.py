#!/usr/bin/env python3
"""
HOMESETS — Fixture Validator Mutation & Negative Test Suite (Zero Dependencies)
Validates that validate_fixtures.py correctly rejects malformed, invalid,
duplicate, and unreferenced domain entities.
"""

import sys
import copy
import json
import tempfile
import unittest
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(TOOLS_DIR))

from validate_fixtures import (
    validate_catalog_data,
    validate_scenarios_data,
    validate_fixtures,
    DEFAULT_CATALOG_PATH,
    DEFAULT_SCENARIOS_PATH,
)


class TestRealFixtures(unittest.TestCase):
    """Ensures production fixtures pass strict validation cleanly."""

    def setUp(self):
        with open(DEFAULT_CATALOG_PATH, "r", encoding="utf-8") as f:
            self.catalog = json.load(f)
        with open(DEFAULT_SCENARIOS_PATH, "r", encoding="utf-8") as f:
            self.scenarios = json.load(f)
        self.valid_ex_ids = {e["id"] for e in self.catalog["exercises"]}

    def test_real_catalog_passes(self):
        ok, msg = validate_catalog_data(self.catalog)
        self.assertTrue(ok, f"Real catalog failed validation: {msg}")

    def test_real_scenarios_pass(self):
        ok, msg = validate_scenarios_data(self.scenarios, valid_exercise_ids=self.valid_ex_ids)
        self.assertTrue(ok, f"Real scenarios failed validation: {msg}")

    def test_full_fixture_validation_passes(self):
        self.assertTrue(validate_fixtures())


class TestCatalogMutations(unittest.TestCase):
    """Mutates catalog data and asserts validation failure."""

    def setUp(self):
        with open(DEFAULT_CATALOG_PATH, "r", encoding="utf-8") as f:
            self.catalog = json.load(f)

    def test_catalog_missing_required_field(self):
        mutated = copy.deepcopy(self.catalog)
        del mutated["exercises"][0]["technique_cues_ar"]
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("missing required field 'technique_cues_ar'", msg)

    def test_catalog_duplicate_id(self):
        mutated = copy.deepcopy(self.catalog)
        mutated["exercises"][1]["id"] = mutated["exercises"][0]["id"]
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("Duplicate exercise ID", msg)

    def test_catalog_duplicate_slug(self):
        mutated = copy.deepcopy(self.catalog)
        mutated["exercises"][1]["slug"] = mutated["exercises"][0]["slug"]
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("Duplicate exercise slug", msg)

    def test_catalog_invalid_pattern(self):
        mutated = copy.deepcopy(self.catalog)
        mutated["exercises"][0]["pattern"] = "INVALID_MOVEMENT_PATTERN"
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("invalid pattern", msg)

    def test_catalog_unapproved_equipment(self):
        mutated = copy.deepcopy(self.catalog)
        mutated["exercises"][0]["required_equipment"].append("kettlebell_unapproved")
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("unapproved equipment", msg)

    def test_catalog_broken_alternative_link(self):
        mutated = copy.deepcopy(self.catalog)
        mutated["exercises"][0]["unprovocative_alternative_id"] = "non_existent_exercise_id"
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("references non-existent unprovocative_alternative_id", msg)

    def test_catalog_negative_skill_prerequisite(self):
        mutated = copy.deepcopy(self.catalog)
        mutated["exercises"][0]["skill_prerequisite_reps"] = -3
        ok, msg = validate_catalog_data(mutated)
        self.assertFalse(ok)
        self.assertIn("skill_prerequisite_reps must be integer >= 0", msg)


class TestScenarioMutations(unittest.TestCase):
    """Mutates scenario data and asserts validation failure."""

    def setUp(self):
        with open(DEFAULT_CATALOG_PATH, "r", encoding="utf-8") as f:
            self.catalog = json.load(f)
        with open(DEFAULT_SCENARIOS_PATH, "r", encoding="utf-8") as f:
            self.scenarios = json.load(f)
        self.valid_ex_ids = {e["id"] for e in self.catalog["exercises"]}

    def test_scenarios_count_under_100(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"] = mutated["scenarios"][:99]
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("Expected at least 100 scenarios", msg)

    def test_scenarios_duplicate_id(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][1]["id"] = mutated["scenarios"][0]["id"]
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("Duplicate scenario ID", msg)

    def test_scenarios_duplicate_vector(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][1]["input_state"] = copy.deepcopy(mutated["scenarios"][0]["input_state"])
        mutated["scenarios"][1]["expected_output"] = copy.deepcopy(mutated["scenarios"][0]["expected_output"])
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("Duplicate scenario vector detected", msg)

    def test_scenarios_invalid_category(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][0]["category"] = "UNREGISTERED_CATEGORY"
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("invalid category", msg)

    def test_scenarios_empty_input_state(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][0]["input_state"] = {}
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("input_state must be a non-empty object", msg)

    def test_scenarios_invalid_action_enum(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][0]["expected_output"]["action"] = "FABRICATED_ACTION"
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("invalid action enum", msg)

    def test_scenarios_referential_integrity_in_input(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][0]["input_state"]["exercise"] = "non_existent_exercise"
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("references unknown exercise 'non_existent_exercise'", msg)

    def test_scenarios_referential_integrity_in_output(self):
        mutated = copy.deepcopy(self.scenarios)
        mutated["scenarios"][5]["expected_output"]["next_exercise"] = "unregistered_movement_xyz"
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("references unknown exercise 'unregistered_movement_xyz'", msg)

    def test_scenarios_all_positive_fails(self):
        mutated = copy.deepcopy(self.scenarios)
        for s in mutated["scenarios"]:
            s["is_negative_case"] = False
        ok, msg = validate_scenarios_data(mutated, self.valid_ex_ids)
        self.assertFalse(ok)
        self.assertIn("Scenarios must contain both positive and negative cases", msg)


class TestFileLevelValidation(unittest.TestCase):
    """Tests file error handling."""

    def test_missing_catalog_file(self):
        non_existent = Path("non_existent_catalog_path.json")
        self.assertFalse(validate_fixtures(catalog_path=non_existent))

    def test_malformed_json_file(self):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False, encoding="utf-8") as f:
            f.write("{ broken json: [")
            tmp_path = Path(f.name)
        try:
            self.assertFalse(validate_fixtures(catalog_path=tmp_path))
        finally:
            if tmp_path.exists():
                tmp_path.unlink()


if __name__ == "__main__":
    unittest.main()
