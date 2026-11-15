# ADR-001: Pure-Dart Workout Plan Engine Isolation

- **Status:** Recommended (Architecture Baseline)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Consulted:** Product Owner (Ahmed), Project Lead
- **Authority Reference:** `DECISION_REGISTER.md` (D02, D17), `docs/PROJECT_RULES.md`

---

## Context & Problem Statement

HOMESETS must generate intelligent, deterministic workout progressions, manage fatigue, filter movements around joint pain, and adapt session volume to busy working schedules. In many cross-platform apps, workout logic is tightly coupled to UI frameworks (Flutter widgets), device state, or database ORMs. This causes slow test cycles, difficult regression tracking, and fragility during UI redesigns.

How should the core fitness calculation and double progression algorithms be architected to ensure 100% determinism, sub-second testing, and long-term maintainability?

---

## Decision Drivers

1. **Deterministic Reproducibility (D17):** Identical inputs (past logs, equipment, pain flags, rest) must yield identical session outputs.
2. **Sub-Second Test Velocity:** The entire domain test matrix ($\ge 100$ scenarios) must execute without spinning up Flutter harnesses, emulators, or native C-bindings.
3. **Decoupling from Presentation:** UI redesigns or framework changes must have zero impact on fitness safety algorithms.
4. **Zero Runtime AI Cost:** Pure rule-based algorithm; no remote LLMs or on-device inference engines.

---

## Considered Options

- **Option A: Pure-Dart Domain Layer (`lib/domain/engine/`)**
  - Completely isolated pure Dart package/directory with zero imports from `package:flutter/...` or `package:drift/...`.
  - Consumes and outputs pure, immutable Dart data classes.
- **Option B: Coupled Service Layer with Database Access**
  - Engine classes directly execute queries against the local SQLite database to pull history and compute next sets.
- **Option C: Client-Side Embedded Scripting / Dynamic Rules**
  - Rules written in JSON-logic or Lua interpreted at runtime.

---

## Decision Outcome

**Chosen Option:** **Option A: Pure-Dart Domain Layer (`lib/domain/engine/`)**.

### Architectural Contract:
1. Files within `lib/domain/engine/` are strictly forbidden from importing `package:flutter/...`, `dart:ui`, or any persistence/ORM libraries.
2. All calculations are pure functions or deterministic state machines taking `UserProfile`, `EquipmentInventory`, `AvoidedAreas`, and `SetHistory` as immutable parameters.
3. Random persistence identifiers (e.g. SQLite primary keys) are injected at persistence boundaries, never inside domain engine calculations.
4. Enforced in CI via a strict static check in `.github/workflows/foundation.yml`.

### Positive Consequences:
- Domain test suite executes 100+ complex progression scenarios in $<1$ second.
- Mathematical safety invariants (pain-stop precedence, volume caps) are verifiable in isolation.

### Negative Consequences:
- Requires repository layer / mappers to convert database entities to domain entities before calling engine methods.
