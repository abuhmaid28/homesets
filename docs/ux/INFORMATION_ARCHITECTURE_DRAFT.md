# HOMESETS — Information Architecture & Screen Inventory (Draft Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G1/G3 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)

---

## 1. Global Navigation Architecture

HOMESETS uses a flat, bottom-anchored 3-tab navigation hierarchy optimized for rapid access and zero clutter. During active workouts, global navigation is replaced by a focused, modal Workout Player shell to eliminate accidental navigation away from an ongoing session.

```text
[ Root Navigation Shell (Bottom Navigation Bar) ]
       │
       ├── Tab 1: اليوم (Today) [Default Home Tab]
       │     ├── Next Workout Card (Primary CTA: Start Workout)
       │     ├── Quick Lite Mode (15 min) CTA
       │     ├── Weekly Consistency Ring
       │     ├── Exercise Preview Sheet (Modal Bottom Sheet)
       │     └── Active Workout Recovery Banner (Conditional State)
       │
       ├── Tab 2: التقدم (Progress Hub)
       │     ├── Photos Sub-Tab (Gallery, Capture Guide, Slider Compare)
       │     ├── Weight Sub-Tab (Daily Log, 7-Day Rolling Trend Chart)
       │     ├── Strength Sub-Tab (Movement Overload Curves)
       │     └── Meals Sub-Tab (Daily 5-Point Checklist & Cheap Protein Guide)
       │
       └── Tab 3: الإعدادات (Settings & Safety)
             ├── Training Profile (Goal, Equipment, Avoided Joints, Time)
             ├── App Preferences (Theme: Dark/Light, Language: AR/EN)
             ├── Notifications (Daily 3:30 PM Reminder Toggle & Time Picker)
             ├── Data Management (Export Backup, Import Backup, Reset All Data)
             └── About & Safety Disclaimer (Non-Medical Notice & App Version)
```

### Active Workout Player (Modal Experience)
When a workout starts, the bottom navigation bar is hidden and the app enters the full-screen **Workout Player**:
```text
[ Full-Screen Workout Player ]
       ├── Top Bar: Workout Name, Set Counter, Exit / Pause Button
       ├── Middle Area: Current Movement, Exercise Visual Cue, Target Reps & Resistance
       ├── Lower Thumb Zone: Rep Stepper, Log Set CTA, Rating Pills (Easy / Right / Hard)
       ├── Automated Overlay: Rest Timer Countdown (with +30s / Skip)
       └── Sub-Modals:
             ├── Exercise Swap Sheet (Equipment constraint or Joint fatigue)
             └── Pain Stop Modal (Immediate safe session termination)
```

---

## 2. Comprehensive Screen & Sheet Inventory

| Screen ID | Screen / Component Name | Type | Arabic Title | Primary User Action |
| :--- | :--- | :--- | :--- | :--- |
| **SCR-01** | Splash / Launcher Gate | Screen | البداية | Check initialization and profile existence; route to Onboarding or Today. |
| **SCR-02** | Onboarding: Welcome & Goal | Step | أهلاً بيك في هوم سيتس | Select training goal (Build Muscle default). |
| **SCR-03** | Onboarding: Physical Baseline | Step | بياناتك البدنية | Enter Height, Weight, Age, Pull-up & Push-up baseline reps. |
| **SCR-04** | Onboarding: Equipment & Time | Step | الأدوات والوقت | Toggle pull-up bar, resistance bands, session duration (15–30 min). |
| **SCR-05** | Onboarding: Pain Areas & Setup | Step | تجنب الإصابات والتفضيلات | Select joint exclusion tags, language, theme, reminder consent. |
| **SCR-06** | Today Screen | Screen (Tab 1) | اليوم | Tap "ابدأ التمرين" ($\le 3$ taps to train) or "Lite Mode". |
| **SCR-07** | Session Preview Sheet | Bottom Sheet | تفاصيل التمرين | View scheduled exercises, target sets/reps, and estimated duration. |
| **SCR-08** | Workout Player | Full Screen | شاشة التمرين | Log completed set reps, view cues, control rest timer. |
| **SCR-09** | Rest Timer Modal | Overlay / Sheet | وقت الراحة | View circular rest countdown, +30s, or skip rest. |
| **SCR-10** | Exercise Swap Sheet | Bottom Sheet | تبديل التمرين | Select alternative exercise filtered by muscle and equipment. |
| **SCR-11** | Pain Alert / Safety Modal | Dialog | تنبيه ألم | Confirm joint pain, trigger emergency stop or safe swap. |
| **SCR-12** | Workout Summary | Screen | عاش يا بطل! | Review duration, volume, next recovery advice; return to Today. |
| **SCR-13** | Progress Hub: Photos | Screen (Tab 2) | صور التطور | View historical angles (Front/Side/Back), launch camera capture. |
| **SCR-14** | Photo Capture with Silhouette | Full Screen | التقاط صورة جديدة | Align body against transparent silhouette outline; capture and save. |
| **SCR-15** | Photo Compare Slider | Full Screen | مقارنة الصور | Slide interactive divider between Date A and Date B photos. |
| **SCR-16** | Progress Hub: Weight & Trends | Screen (Tab 2) | الوزن والمعدل | Log today's weight; view 7-day rolling trend chart. |
| **SCR-17** | Progress Hub: Strength Charts | Screen (Tab 2) | تطور القوة | View progression curves for pull-ups and push-up ladders. |
| **SCR-18** | Progress Hub: Meal Checklist | Screen (Tab 2) | جدول الوجبات | Tick 5 daily meal checkboxes; view cheap protein food suggestions. |
| **SCR-19** | Settings Main Screen | Screen (Tab 3) | الإعدادات | Access profile settings, preferences, reminders, backup utilities. |
| **SCR-20** | Edit Equipment & Avoid Areas | Screen | تعديل الأدوات والإصابات | Update bands owned or toggle newly sore joint areas. |
| **SCR-21** | Reminder Settings | Screen | ميعاد التنبيه | Set daily notification time (default 3:30 PM) and view MagicOS tips. |
| **SCR-22** | Backup & Restore Screen | Screen | النسخ الاحتياطي | Trigger single-file export or import archive with schema validation. |
| **SCR-23** | Safety Disclaimer & About | Screen | عن التطبيق وإخلاء المسؤولية | Read non-medical advice disclaimer, version number, asset licenses. |
| **SCR-24** | Session Recovery Banner | In-line Alert | استئناف تمرين سابق | Displayed on Today screen if a previous session was interrupted. |

---

## 3. Ergonomic Zone Mapping (Lower Thumb-Zone Focus)

In accordance with Product Rule D08/D16, high-frequency interactive elements in the Workout Player are mapped to the lower 40% of the display viewport:

```text
┌─────────────────────────────────┐
│ Top Bar: Session & Exit [Secondary] │  <- Safe, non-accidental tap zone
├─────────────────────────────────┤
│                                 │
│                                 │
│ Exercise Demonstration & Cues   │  <- High visibility viewing area
│ [Read-Only Visual]              │
│                                 │
│                                 │
├─────────────────────────────────┤
│ Target Reps & Tension Badge     │
├─────────────────────────────────┤
│   [-]   [ 10 تكرار ]   [+]      │  <- Lower Thumb Zone (Primary)
│                                 │
│  [     تسجيل المجموعة (56dp)    ] │  <- Primary Tap Target (Oversized)
│                                 │
│ [سهل]     [مظبوط]      [صعب]     │  <- Quick Effort Feedback Pills
└─────────────────────────────────┘
```
