# ADR-002: Presentation State Management Architecture

- **Status:** Proposed (Owner Approval Pending for Milestone P3)
- **Date:** 2026-11-15
- **Deciders:** Antigravity (Engineering Architecture)
- **Authority Reference:** `docs/PROJECT_RULES.md`, `docs/DECISION_REGISTER.md` (D01, D02)

---

## Context & Problem Statement

The interactive workout experience in HOMESETS requires responsive state transitions:
1. Today Screen: 1-Tap launch into workout session.
2. Workout Player: Real-time rep stepping, set completion, and dynamic transition to rest timer.
3. Rest Timer: Live 1-second countdown ticker with pause, skip, and +30s extensions.
4. Pain Stop: Instant modal interruption from any active exercise.

We must select a state management solution that provides high testability, minimal boilerplate, predictable lifecycle disposal, and zero unnecessary external dependencies.

---

## Decision Drivers

1. **Simplicity & Maintainability:** Avoid bloated dependency graphs or heavy code generation for simple UI screens.
2. **Deterministic Widget Testing:** Ability to mock or inject controllers in widget tests without global singleton contamination.
3. **Timer Ergonomics:** Clean cancellation and ticking of 90s rest timers without memory leaks.
4. **Dependency Minimization:** Preference for Flutter built-ins or standard lean solutions.

---

## Considered Options

- **Option A: Flutter Native `ChangeNotifier` / `ValueNotifier` + `InheritedNotifier`**
  - Zero external packages. Standard Flutter SDK primitives.
- **Option B: Riverpod (`flutter_riverpod`)**
  - Powerful compile-safe dependency injection and reactive state. Requires external packages (`riverpod`, `flutter_riverpod`).
- **Option C: Bloc (`flutter_bloc`)**
  - Strict event-driven architecture. Highly testable, but substantial boilerplate for small screens.

---

## Decision Outcome

**Recommended Option:** **Option A: Flutter Native `ChangeNotifier` / `ValueNotifier` + Repository Injection**.

### Rationale:
HOMESETS has a bounded scope (3 core tabs, 1 active workout session state machine). Introducing a heavy framework like Riverpod or Bloc adds 3–5 external packages with complex version resolution risks. Standard Flutter `ChangeNotifier` / `ValueNotifier` controllers scoped via `InheritedWidget` (or clean provider pattern) provide 100% of the required functionality with **zero added pub packages**.

### Positive Consequences:
- Zero external package dependencies for state management.
- Complete compatibility across future Flutter versions without upgrade friction.
- Straightforward mockability in widget tests.

### Negative Consequences / Risks:
- Manual controller disposal must be rigorously maintained in `StatefulWidget.dispose()`.
