# HOMESETS — Domain Model & Immutable Contract Specification

**Document Status:** [Active Domain Specification]  
**Author:** Antigravity (Gemini 3.8 Flash High)  
**Date:** 2026-11-15  
**Campaign:** C2-MEGA (Issue #8)  
**Authority Reference:** `DECISION_REGISTER.md` (D04, D05, D07, D09, D17), `docs/PROJECT_RULES.md`  

---

## 1. Domain Vocabulary & Semantic Definitions

The HOMESETS domain model establishes unambiguous terminology for calisthenics, resistance/assistance bands, and recovery:

- **UserProfile:** The local user's physical baseline, shift work schedule, and primary fitness goal.
- **EquipmentInventory:** The confirmed hardware available to the user. Strictly constrained by Decision D09 to:
  1. `pull_up_bar` (Doorframe or wall-mounted bar)
  2. `resistance_bands` (Loop bands and tube bands with handles/anchors)
  3. `bodyweight` (Floor space, sturdy chair/door)
  *Explicitly Excluded:* Barbells, dumbbells, weight plates, weighted vests, backpack loading.
- **BandApplicationMode:** Critical physical distinction between band usages:
  - `ASSISTANCE` (e.g. Band looped under foot during pull-ups): Band tension *subtracts* from bodyweight load. A thicker band means *less* muscular effort. Progressing means moving to a *thinner* band!
  - `RESISTANCE` (e.g. Band bent-over rows, bicep curls, band push-ups): Band tension *adds* load. A thicker band means *more* muscular effort. Progressing means moving to a *thicker* band!
- **Exercise:** An immutable movement archetype (e.g., Pull-Up, Push-Up, Band Row, Squat).
- **ExerciseVariation:** A specific biomechanical instantiation of an exercise (e.g., Wide-Grip Pull-Up, Neutral-Grip Pull-Up, Negative-Only Pull-Up).
- **AvoidedJointArea:** Anatomical regions flagged by the user for protection (e.g., `shoulder_right`, `elbow_left`, `wrist`, `lower_back`).
- **TargetRepBracket:** A bounded integer range defining the hypertrophy target (e.g., `min_reps: 8, max_reps: 10`).
- **SetLog:** The recorded execution record of a single completed or aborted set.
- **EgyptianExertionRating:** Cultural RPE equivalent:
  - `EASY_RESERVE` (`فاضل طاقة (سهل) 💪`): Estimated 3+ reps in reserve.
  - `TARGET_SWEETSPOT` (`مظبوط ومثالي 👍`): Estimated 1–2 reps in reserve. Target stimulation.
  - `MAX_EFFORT` (`على الآخر (أقصى مجهود) 🔥`): 0 reps in reserve (near-failure).
  - `PAIN_STOPPED` (`🛑 ألم مفصلي غير طبيعي`): Set terminated prematurely due to joint pain.
- **ScheduledSession:** A generated workout containing 2–3 exercises, targeting specific muscle groups, bounded by a 15–30 minute time ceiling.

---

## 2. Immutable Entity Contracts (Pseudo-Code Specification)

All domain entities are immutable data records. They contain zero Flutter widget logic and zero database queries.

```text
// ==================== PROFILE & EQUIPMENT ====================

Record UserProfile:
    id: String (UUID v4)
    createdAt: DateTime (UTC)
    baselineAge: Integer (e.g. 26)
    baselineHeightCm: Float (e.g. 190.0)
    baselineWeightKg: Float (e.g. 60.0)
    targetWeightKg: Float (e.g. 80.0)
    wakeTimeMinutes: Integer (e.g. 900 -> 3:00 PM)
    shiftStartMinutes: Integer (e.g. 1140 -> 7:00 PM)
    shiftEndMinutes: Integer (e.g. 240 -> 4:00 AM)
    targetWorkoutsPerWeek: Integer (Default: 4)

Record BandItem:
    id: String
    nominalColor: String (e.g. "Red", "Black", "Purple")
    relativeTensionRank: Integer (1 = Lightest, 5 = Heaviest)
    estimatedResistanceKgMin: Float
    estimatedResistanceKgMax: Float

Record EquipmentInventory:
    hasPullUpBar: Boolean
    hasDoorAnchor: Boolean
    availableBands: List<BandItem>
    canDoParallelDips: Boolean

// ==================== EXERCISE & VARIATION ====================

Enum MovementPattern:
    VERTICAL_PULL, HORIZONTAL_PULL, VERTICAL_PUSH, HORIZONTAL_PUSH,
    QUAD_DOMINANT, HIP_HINGE, CORE_ISOMETRIC, ISOLATION_ARM

Enum JointImpactTag:
    SHOULDER_ANTERIOR, SHOULDER_SUBACROMIAL, ELBOW_MEDIAL,
    ELBOW_LATERAL, WRIST_COMPRESSION, LUMBAR_SHEAR, KNEE_PATELLAR

Record ExerciseDefinition:
    id: String (e.g. "pull_up_wide")
    slug: String
    nameArabic: String (e.g. "عقلة قبضة واسعة")
    nameEnglish: String (e.g. "Wide-Grip Pull-Up")
    pattern: MovementPattern
    primaryMuscles: List<String> (e.g. ["latissimus_dorsi", "biceps_brachii"])
    secondaryMuscles: List<String> (e.g. ["rhomboids", "forearms"])
    jointStressTags: List<JointImpactTag>
    requiredEquipment: List<String>
    supportsBandAssistance: Boolean
    supportsBandResistance: Boolean
    unprovocativeAlternativeId: Nullable<String>

// ==================== SESSION & LOGGING ====================

Record PlannedSet:
    setIndex: Integer (1, 2, 3)
    targetMinReps: Integer
    targetMaxReps: Integer
    prescribedBandId: Nullable<String>
    prescribedApplicationMode: Nullable<BandApplicationMode>
    targetRestSeconds: Integer (e.g. 90)

Record SetLog:
    setIndex: Integer
    performedReps: Integer
    bandUsedId: Nullable<String>
    applicationMode: Nullable<BandApplicationMode>
    exertion: EgyptianExertionRating
    isPainStopped: Boolean
    painNote: Nullable<String>
    completedAt: DateTime (UTC)

Record CompletedWorkoutSession:
    id: String
    scheduledSessionId: String
    startedAt: DateTime (UTC)
    endedAt: DateTime (UTC)
    totalDurationSeconds: Integer
    isLiteMode: Boolean
    completedSets: List<SetLog>
    isEmergencyStopped: Boolean
    emergencyStopReason: Nullable<String>
```

---

## 3. Identifiers & Determinism Boundary

In accordance with Architecture Blocker §4:
1. **Engine Inputs / Outputs:** Domain algorithms never generate random numbers or random UUIDs. Given the same inputs, the engine returns identical `ScheduledSession` structures with deterministic set brackets.
2. **Persistence Identifiers:** Entity IDs are generated at the repository boundary when inserting new rows into SQLite, keeping pure computation 100% deterministic and testable.
