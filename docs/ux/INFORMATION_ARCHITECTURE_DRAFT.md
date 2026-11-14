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

## 2. Comprehensive Screen & Component Inventory

> **Architecture Clarification:** The 24 entries below represent the complete catalog of visual destinations, including **3 root navigation tabs, 4 setup wizard steps, 8 modal bottom sheets/drawers, 3 dialogs, and 1 in-line state banner**. They do **not** represent 24 standalone top-level activity routes.

| Screen ID | Screen / Component Name | Entry Classification | Arabic Title | Primary User Action |
| :--- | :--- | :--- | :--- | :--- |
| **SCR-01** | Splash / Launcher Gate | Root Route | البداية | Check initialization and profile existence; route to Setup or Today. |
| **SCR-02** | App Setup: Welcome & Goal | Wizard Step | أهلاً بيك في هوم سيتس | Confirm confirmed MVP goal (بناء العضلات والقوة; additional goals post-MVP). |
| **SCR-03** | App Setup: Physical Baseline | Wizard Step | بياناتك البدنية | Enter Height, Weight, Age, Pull-up & Push-up baseline reps (blank fields). |
| **SCR-04** | App Setup: Equipment & Time | Wizard Step | الأدوات والوقت | Toggle pull-up bar, resistance bands, target session duration (15–30 min). |
| **SCR-05** | App Setup: Pain Areas & Prefs| Wizard Step | تجنب الإصابات والتفضيلات | Select joint exclusion tags, language, theme, reminder consent. |
| **SCR-06** | Today Screen | Root Tab 1 | اليوم | Tap "ابدأ التمرين" ($\le 3$ taps to train) or "Lite Mode". |
| **SCR-07** | Session Preview Sheet | Modal Bottom Sheet | تفاصيل التمرين | View scheduled exercises, target sets/reps, and estimated duration. |
| **SCR-08** | Workout Player | Full-Screen Modal | شاشة التمرين | Log completed set reps, view cues, control rest timer. |
| **SCR-09** | Rest Timer Modal | Modal Drawer | وقت الراحة | View circular rest countdown, +30s, or skip rest. |
| **SCR-10** | Exercise Swap Sheet | Modal Bottom Sheet | تبديل اختياري | Select alternative exercise filtered by muscle and equipment. |
| **SCR-11** | Pain Alert / Safety Modal | Safety Dialog | تنبيه ألم وإيقاف | Prioritize immediate stop and joint rest; safe alternatives offered post-pain. |
| **SCR-12** | Workout Summary | Screen Route | عاش يا بطل! | Review duration, volume, next recovery advice; return to Today. |
| **SCR-13** | Progress Hub: Photos | Root Tab 2 Subview | صور التطور | View historical angles (Front/Side/Back), launch camera capture. |
| **SCR-14** | Photo Capture with Silhouette | Full-Screen Modal | التقاط صورة جديدة | Align body against transparent silhouette outline; capture and save. |
| **SCR-15** | Photo Compare Slider | Full-Screen Modal | مقارنة الصور | Slide interactive divider between Date A and Date B photos. |
| **SCR-16** | Progress Hub: Weight & Trends | Root Tab 2 Subview | الوزن والمعدل | Log today's weight; view 7-day trailing calendar rolling average. |
| **SCR-17** | Progress Hub: Strength Charts | Root Tab 2 Subview | تطور القوة | View progression curves for pull-ups and push-up ladders. |
| **SCR-18** | Progress Hub: Meal Checklist | Root Tab 2 Subview | جدول الوجبات | Tick 5 daily meal checkboxes; view cheap protein food suggestions. |
| **SCR-19** | Settings Main Screen | Root Tab 3 | الإعدادات | Access profile settings, preferences, reminders, backup utilities. |
| **SCR-20** | Edit Equipment & Avoid Areas | Screen Route | تعديل الأدوات والإصابات | Update bands owned or toggle newly sore joint areas. |
| **SCR-21** | Reminder Settings | Screen Route | ميعاد التنبيه | Set daily notification time (default 3:30 PM) and view MagicOS tips. |
| **SCR-22** | Backup & Restore Screen | Screen Route | النسخ الاحتياطي | Trigger single-file export or two-phase validated restore. |
| **SCR-23** | Safety Disclaimer & About | Screen Route | عن التطبيق وإخلاء المسؤولية | Read non-medical advice disclaimer, version number, asset licenses. |
| **SCR-24** | Session Recovery Banner | In-line Alert Banner | استئناف تمرين سابق | Conditional banner on Today screen if a previous session was interrupted. |

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
