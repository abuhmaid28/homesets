# HOMESETS — User Flows & State Transitions (Draft Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G1/G3 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)

---

## 1. Flow Index
1. **Flow 1:** First-Time Onboarding & Engine Initialization
2. **Flow 2:** Standard Daily Workout (Today $\to$ Start $\to$ Log $\to$ Summary)
3. **Flow 3:** Exhausted Pre-Shift "Lite Mode" (15 Minutes)
4. **Flow 4:** Mid-Workout Exercise Swap (Equipment or Joint Fatigue)
5. **Flow 5:** Emergency Pain Stop & Safety Exclusion
6. **Flow 6:** Guilt-Free Return After Missed Days (7+ Days Absence)
7. **Flow 7:** Progress Photo Capture & Slider Comparison
8. **Flow 8:** Daily Weight Logging & 7-Day Trend
9. **Flow 9:** Manual Single-File Backup Export & Validated Restore
10. **Flow 10:** Daily Pre-Shift Reminder Notification & App Launch

---

## 2. Detailed Flow Specifications

### Flow 1: First-Time Onboarding & Engine Initialization
```text
[App Launch]
    │
    ▼
(Profile exists in DB?)
    ├── Yes ──> [Navigate to Today Screen (SCR-06)]
    └── No  ──> [Welcome Screen: Goal Confirmation (SCR-02)]
                    │ Tap "متابعة"
                    ▼
                [Physical Baseline Form (SCR-03)]
                    │ Height (cm), Weight (kg), Age, Baseline Reps
                    │ Tap "التالي"
                    ▼
                [Equipment & Time Preferences (SCR-04)]
                    │ Toggle: Pull-up bar [x], Resistance Bands [x]
                    │ Duration: 15–30 min
                    │ Tap "التالي"
                    ▼
                [Avoid Areas & Local Settings (SCR-05)]
                    │ Injury tags: None / Shoulders / Knees / Lower back
                    │ Language: Arabic (RTL) | Theme: Dark Performance Lime
                    │ Notification: 3:30 PM Pre-shift [x]
                    │ Tap "إنهاء وبدء برنامجي"
                    ▼
                [Plan Engine Generates Initial 3-Week Cycle]
                    │
                    ▼
                [Today Screen Active (First Workout Ready)]
```

---

### Flow 2: Standard Daily Workout (Today $\to$ Start $\to$ Log $\to$ Summary)
```text
[Launch App at ~3:45 PM]
    │
    ▼
[Today Screen (SCR-06)]
    │ Inspect Workout Card: "سحب وضهر - 25 دقيقة - 3 تمارين"
    │ Tap "ابدأ التمرين (Start Workout)" (Tap 1)
    ▼
[Workout Player (SCR-08) Active]
    │ Screen WakeLock engaged
    │ Current Movement: Pull-ups (Set 1 of 3, Target: 8–10 reps)
    │ Perform physical set
    │ Tap [-] or [+] to adjust logged reps (Default: target)
    │ Tap "تسجيل المجموعة" (Tap 2)
    ▼
[Rest Timer Drawer Appears (SCR-09)]
    │ Tactile vibration confirms log
    │ 90-second circular countdown running
    │ Optional: Tap feedback pill [سهل] / [مظبوط] / [صعب]
    │ Rest ends (or user taps "تخطي الراحة")
    ▼
[Next Set or Next Exercise]
    │ Repeat until all prescribed sets and exercises complete
    ▼
[Workout Summary Screen (SCR-12)]
    │ "عاش يا بطل! كملت تمرين النهاردة في 22 دقيقة"
    │ Volume recap: 9 sets, 82 total reps
    │ Recovery note: "عضلات الضهر محتاجة 48 ساعة راحة"
    │ Tap "العودة للرئيسية"
    ▼
[Today Screen Updated (Consistency Ring advances: e.g. 1/4)]
```

---

### Flow 3: Exhausted Pre-Shift "Lite Mode" (15 Minutes)
```text
[Today Screen (SCR-06)]
    │ User feels fatigued before 5:00 PM shift
    │ Tap "تمرين سريع 15 دقيقة (Lite Mode)"
    ▼
[Plan Engine Filter]
    │ Truncates accessory exercises
    │ Selects top 2 key compound movements (e.g. Chin-ups + Band Push-ups)
    │ Sets sets per exercise to 2 (Total: 4 hard sets)
    ▼
[Workout Player Launches in Lite Mode]
    │ Visual badge: "الوضع السريع ⚡"
    │ Complete 4 sets in ~12–15 minutes
    ▼
[Summary Screen]
    │ "تمرين سريع وممتاز! حافظت على استمراريتك النهاردة"
    │ Consistency Ring awarded full credit
```

---

### Flow 4: Mid-Workout Exercise Swap
```text
[Workout Player (SCR-08)]
    │ Active Movement: Band Overhead Press
    │ User has door anchor issue or mild shoulder stiffness
    │ Tap "تبديل (Swap)"
    ▼
[Exercise Swap Bottom Sheet (SCR-10)]
    │ Engine queries exercises matching:
    │   - Primary Muscle: Shoulders / Chest
    │   - Equipment: Bands owned
    │   - Excludes active avoided joints
    │ Options displayed:
    │   1. Band Lateral Raise (رفع جانبي بالمقاومة)
    │   2. Band Incline Push-up (ضغط مائل)
    │ Tap selected alternative
    ▼
(Apply swap for:)
    ├── [النهاردة بس (Today only)] ──> Replaces exercise for this session
    └── [دائماً (Permanent)]     ──> Updates program template in database
    ▼
[Workout Player Resumes with Replacement Movement]
```

---

### Flow 5: Emergency Pain Stop & Safety Exclusion
```text
[Workout Player (SCR-08)]
    │ Acute discomfort during set
    │ Tap prominent secondary button "في ألم (Pain)"
    ▼
[Safety Alert Modal (SCR-11)]
    │ "سلامتك أهم من أي تمرين! حابب توقف التمرين ولا نبدل الحركة لحركة مريحة؟"
    ├── Option A: [تبديل الحركة] ──> Routes to Flow 4 (Swap Sheet)
    └── Option B: [وقف التمرين فوراً]
            │
            ▼
        [Emergency Stop Confirmed]
            │ Completed sets preserved in DB
            │ App flags exercise joint group as sensitive
            │ Non-medical advisory note: "ريح المفصل واشرب مياه، وماتضغطش على نفسك أبداً"
            ▼
        [Return to Today Screen with Session Marked Partial]
```

---

### Flow 6: Guilt-Free Return After Missed Days (7+ Days Absence)
```text
[App Launch after 9-day gap]
    │
    ▼
(Check: Current Date - Last Completed Workout Date > 7 days?)
    │
    ├── Yes:
    │     [Today Screen Displays Re-Entry Card]
    │     Banner: "حمد الله على السلامة يا بطل! 👏"
    │     Subtext: "عشان بقالك فترة موقف، جهزنالك تمرين خفيف وسريع لإعادة تنشيط العضلات وتجنب الشد العضلي"
    │     Next Session modified: Volume reduced by 35%
    │     Zero streak reset penalty
    │
    └── No:
          Standard rotation continues
```

---

### Flow 7: Progress Photo Capture & Slider Comparison
```text
[Progress Hub (SCR-13) -> Photos Tab]
    │
    ├── Action A: Capture New Photo
    │     │ Tap "التقاط صورة جديدة"
    │     ▼
    │     [Camera Screen with Silhouette Overlay (SCR-14)]
    │     Select angle: [أمامي Front] / [جانبي Side] / [خلفي Back]
    │     Align body posture against outline
    │     Take photo -> Tap "حفظ الصورة"
    │     File saved directly to `app_flutter/private_photos/{uuid}.png`
    │     (Never exposed to Android MediaStore/Gallery)
    │
    └── Action B: Compare Progress
          │ Tap "مقارنة صورتين (Compare)"
          ▼
          [Photo Compare Slider Screen (SCR-15)]
          Select Photo A (e.g. Week 1) and Photo B (e.g. Week 4)
          Interactive split slider allows horizontal dragging
          Direct visual verification of physique changes
```

---

### Flow 8: Daily Weight Logging & 7-Day Trend
```text
[Progress Hub (SCR-16) -> Weight Tab]
    │ Tap "تسجيل وزن اليوم"
    ▼
[Weight Entry Bottom Sheet]
    │ Large numeric input: e.g. [ 61.2 ] kg
    │ Date defaults to today
    │ Tap "حفظ"
    ▼
[Chart Updates Instantly]
    │ Daily dot plotted on chart
    │ 7-day rolling average calculated: $\bar{w} = \frac{1}{k}\sum_{i=0}^{k-1} w_{t-i}$
    │ Rolling average line updated
    │ If $\Delta \bar{w} < 0.1$ kg over 3 weeks:
    │   Display friendly Egyptian Arabic nutrition nudge
```

---

### Flow 9: Manual Single-File Backup Export & Validated Restore
```text
[Settings (SCR-19) -> Backup & Restore (SCR-22)]
    │
    ├── Action A: Export Backup
    │     │ Tap "تصدير نسخة احتياطية"
    │     ▼
    │     App packages SQLite DB + private photos into `homesets_backup_YYYYMMDD.homesets`
    │     Computes SHA-256 integrity hash
    │     Invokes Android system Share sheet (Save to Downloads, Drive, or PC)
    │
    └── Action B: Restore Backup
          │ Tap "استعادة نسخة احتياطية"
          ▼
          Android SAF File Picker opens -> User selects `.homesets` file
          App verifies:
            1. File format & ZIP decompression
            2. Manifest checksum matches payload
            3. Schema version $\le$ Current app schema version
          If valid:
            Prompt: "هل تريد استبدال البيانات الحالية بالنسخة الاحتياطية؟"
            Confirm -> Restores DB and unpacks photos -> Restarts app state
```

---

### Flow 10: Daily Pre-Shift Reminder Notification & App Launch
```text
[Device System Clock reaches 3:30 PM]
    │
    ▼
(Is daily reminder enabled in Settings?)
    │
    ├── Yes:
    │     Android AlarmManager fires local notification
    │     Notification banner:
    │       "هوم سيتس | وقت تمرينك النهاردة يا بطل! 💪"
    │       "20 دقيقة بس قبل الشغل تفرق في يومك وجسمك."
    │     User taps notification
    │     App opens directly to Today Screen (SCR-06)
    │
    └── No:
          Silent
```
