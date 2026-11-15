# HOMESETS — User Stories & Acceptance Criteria (Draft Proposal)

**Document Status:** [Proposed] — Prepared for Product Owner Gate G1 Review
**Author:** Antigravity (Gemini 3.8 Flash High)
**Date:** 2026-11-14
**Campaign:** C1 (Tracking Issue #4)

---

## Story Index
- **US-01:** First Launch & Guided Profile Setup (Onboarding)
- **US-02:** Starting a Planned Workout in $\le 3$ Taps
- **US-03:** 15-Minute "Lite Mode" Workout on Exhausting Days
- **US-04:** One-Handed Workout Set & Rest Logging
- **US-05:** Set Feedback (Easy / Right / Hard) & Dynamic Overload
- **US-06:** Mid-Workout Exercise Swap & Pain Stop
- **US-07:** Private Progress Photo Capture & Slider Comparison
- **US-08:** Weekly Weight Tracking & 7-Day Rolling Trend
- **US-09:** Strength Charts & Weekly Consistency Tracking
- **US-10:** Daily Meal & Cheap Protein Checklist
- **US-11:** Scheduled 3:30 PM Pre-Shift Reminder
- **US-12:** Interrupted Workout Crash & App-Killed Resume
- **US-13:** Single-File Local Backup & Validated Restore
- **US-14:** Guilt-Free Return After Missed Training Days
- **US-15:** Strict Offline Operation & Network Absence

---

### US-01: First Launch & App Setup (`إعداد التطبيق وبدء برنامجك`)
**As a** new user setting up HOMESETS,
**I want to** configure my physical stats, equipment, time limits, and injury exclusions with blank fields and clear placeholder hints,
**So that** the app immediately generates a personalized home training program tailored to my constraints.

#### Acceptance Criteria
- **Scenario 1.1: Standard app setup flow**
  - **Given** the app is launched for the first time on Android,
  - **When** I progress through the setup screens,
  - **Then** my Goal is displayed as confirmed: **"بناء العضلات والقوة (Build Muscle & Strength)"** (no unapproved selector; additional goals flagged as post-MVP),
  - **And** I enter my personal stats into clean blank fields with placeholder hints (e.g. "مثال: 175 سم", "مثال: 70 كجم", "مثال: 8 تكرارات"),
  - **And** select Equipment (Pull-up bar + Resistance bands),
  - **And** select Preferred Duration (15–30 min target estimate),
  - **And** select Language (Egyptian Arabic RTL) and Theme (Dark Performance Lime),
  - **And** reaching the end immediately loads the Today screen with my first tailored workout generated.
- **Scenario 1.2: Pain area exclusion**
  - **Given** I am on the "Avoid Areas" setup step,
  - **When** I toggle "Lower Back" (أسفل الظهر) to avoid,
  - **Then** any spinal-loading exercise (e.g., heavy bent-over band rows or unassisted Good Mornings) is excluded from my generated plan.

---

### US-02: Starting a Planned Workout in $\le 3$ Taps
**As a** user in a rush before my 5:00 PM work departure,
**I want to** start today's workout in 3 taps or fewer from app launch,
**So that** I spend zero time wondering what to do and begin training immediately.

#### Acceptance Criteria
- **Scenario 2.1: Direct workout start**
  - **Given** the app is opened to the Today screen (Tap 0),
  - **When** I tap the prominent primary button "ابدأ التمرين (Start Workout)" (Tap 1),
  - **Then** the Workout Player screen opens immediately with the first exercise ready to log,
  - **And** total taps from home screen launch to first exercise active is exactly 1 tap.
- **Scenario 2.2: Preview then start**
  - **Given** I am on the Today screen,
  - **When** I tap the workout card to review exercise list (Tap 1),
  - **And** tap "بدء التمرين" at the bottom of the preview sheet (Tap 2),
  - **Then** the Workout Player launches with Set 1 active.

---

### US-03: 15-Minute "Lite Mode" Workout on Exhausting Days
**As an** exhausted user after a long shift or poor sleep,
**I want to** trigger a condensed 15-minute Lite version of today's workout,
**So that** I keep my weekly consistency without burning out or skipping entirely.

#### Acceptance Criteria
- **Scenario 3.1: Lite mode activation**
  - **Given** I am on the Today screen,
  - **When** I tap "تمرين سريع 15 دقيقة (Lite Mode)",
  - **Then** the engine condenses the session to 2 primary compound movements (e.g., Pull-ups and Band Push-ups),
  - **And** provides an estimated target duration of ~15 minutes (not a safety-unaware rigid countdown clock),
  - **And** completing this session counts fully toward my weekly consistency score.

---

### US-04: One-Handed Workout Set & Rest Logging
**As a** user holding my phone in one hand between intense sets,
**I want to** adjust reps and log sets using large buttons in the lower thumb zone,
**So that** logging is effortless and does not disrupt my training flow.

#### Acceptance Criteria
- **Scenario 4.1: Logging a completed set**
  - **Given** I just completed Set 1 of Pull-ups (Target: 8–10 reps, Actual: 9 reps),
  - **When** I adjust reps if needed using the large +/- stepper in the lower 40% of the screen,
  - **And** tap the oversized "تسجيل المجموعة (Log Set)" button ($\ge 56\times 56$ dp),
  - **Then** the set is marked complete with a subtle tactile haptic pulse,
  - **And** the automated Rest Timer modal/drawer begins counting down immediately (default 90s).
- **Scenario 4.2: Screen stays awake**
  - **Given** a workout session is active in the player,
  - **When** the phone sits on a chair or desk for 3 minutes without screen touches,
  - **Then** the screen does not dim or sleep until the session is completed or paused.

---

### US-05: Set Feedback & Exercise-Specific Dynamic Overload [Proposed Safety Policy]
**As a** user progressing over weeks,
**I want to** rate how hard a set felt with one tap,
**So that** the pure-Dart plan engine systematically decides whether to add reps, adjust resistance, or reduce assistance based on exercise mechanics.

#### Acceptance Criteria
- **Scenario 5.1: Rating a set**
  - **Given** I logged a set,
  - **When** the rest timer appears,
  - **Then** 3 distinct rating pills are displayed: "سهل (Easy)", "مظبوط (Right)", "صعب (Hard)",
  - **And** selecting a rating saves the perceived effort with the logged set.
- **Scenario 5.2: Resisted movements double progression (e.g. Band Push-ups / Rows)**
  - **Given** my target bracket for Band Push-ups is 8–12 reps on a calibrated medium-tension band,
  - **When** I hit 12 reps on all prescribed sets with "Right" or "Easy" across 2 consecutive sessions,
  - **Then** next session the engine automatically advances to a heavier-tension band starting back at 8 reps.
- **Scenario 5.3: Assisted movements progression (e.g. Band-Assisted Pull-ups)**
  - **Given** I am performing Band-Assisted Pull-ups with a heavy assistance band,
  - **When** I achieve the top rep bracket cleanly across 2 consecutive sessions,
  - **Then** the engine prescribes a **thinner / lighter assistance band** (or unassisted bodyweight reps) to increase physical difficulty.

---

### US-06: Emergency Pain Stop Precedence & Voluntary Exercise Swap [Proposed Safety Policy]
**As a** user experiencing sudden joint discomfort during an exercise,
**I want** immediate cessation and joint rest to take primary precedence,
**So that** I protect my joints from acute injury rather than being rushed into another provocative exercise.

#### Acceptance Criteria
- **Scenario 6.1: Immediate acute pain stop (Primary Precedence)**
  - **Given** I am performing Overhead Band Press and experience acute shoulder joint discomfort,
  - **When** I tap "في ألم (Pain)",
  - **Then** the app prioritizes stopping the workout immediately: "سلامتك أهم من أي تمرين! هنوقف التمرين دلوقتي عشان تريح المفصل",
  - **And** the session terminates safely, preserving all previously completed sets,
  - **And** the painful joint group is flagged to prevent automatic prescription in subsequent sessions.
- **Scenario 6.2: Voluntary exercise swap (Non-Pain Reason)**
  - **Given** I want to swap an exercise due to equipment access or environmental constraints (e.g., door anchor in use),
  - **When** I select "تبديل اختياري (Voluntary Swap)",
  - **Then** the app suggests pre-filtered alternative exercises hitting similar muscle groups with available tools.

---

### US-07: Private Progress Photo Capture & Slider Comparison
**As a** user aiming to gain 20 kg of defined muscle,
**I want to** capture standardized progress photos and compare them side-by-side,
**So that** I can see physical visual changes even when the scale moves slowly.

#### Acceptance Criteria
- **Scenario 7.1: Capturing photos with silhouette alignment**
  - **Given** I am in the Progress Hub photo section,
  - **When** I take a new photo (Front, Side, or Back),
  - **Then** a transparent silhouette guide overlays the camera view for consistent distance and posture,
  - **And** upon saving, the image is written directly to the app's internal sandbox storage (`getFilesDir()`),
  - **And** the photo does NOT appear in Google Photos, Gallery, or Android MediaStore.
- **Scenario 7.2: Side-by-side slider comparison**
  - **Given** I have photos from Week 1 and Week 4,
  - **When** I open the comparison tool,
  - **Then** an interactive split-screen slider allows dragging left/right to visually inspect muscle definition changes.

---

### US-08: Weekly Weight Tracking & 7-Day Rolling Calendar Trend
**As a** user tracking my bulk towards 80 kg,
**I want to** log my morning weight and see a smoothed 7-day rolling calendar average,
**So that** I don't panic over daily water-weight fluctuations or make bad diet choices based on sparse data.

#### Acceptance Criteria
- **Scenario 8.1: Logging morning weight**
  - **Given** I weigh myself,
  - **When** I tap "تسجيل الوزن" in Progress Hub,
  - **Then** I can enter my weight (e.g., 61.2 kg),
  - **And** the chart updates displaying daily points and the 7-day trailing calendar rolling average.
- **Scenario 8.2: Sparse data guardrail & slow-gain advisory**
  - **Given** fewer than 3 weigh-ins exist in a 7-day calendar window,
  - **When** I view the weight tab,
  - **Then** the rolling average is marked provisional, and NO nutritional portion advice is triggered.
  - **And** only if a verified weekly average change is under 0.1 kg/week across 3 consecutive fully-logged weeks, the app displays a gentle suggestion to add an extra snack.

---

### US-09: Strength Charts & Weekly Consistency Tracking
**As a** user who values consistency over guilt,
**I want to** view my weekly workouts completed versus target,
**So that** I feel motivated by my habits without losing progress to a broken daily streak.

#### Acceptance Criteria
- **Scenario 9.1: Weekly consistency visualization**
  - **Given** my target is 4 workouts per week,
  - **When** I complete 3 workouts by Sunday,
  - **Then** the consistency ring displays "3 من 4 تمارين هذا الأسبوع (75%)",
  - **And** no streak reset warning or negative shaming copy is displayed on Monday morning.
- **Scenario 9.2: Strength progression curve**
  - **Given** I have logged Pull-ups across 6 sessions,
  - **When** I open the Strength tab,
  - **Then** a clean line chart plots my maximum reps per set over time.

---

### US-10: Daily Meal & Cheap Protein Checklist
**As a** budget-conscious user needing enough calories and protein to grow,
**I want a** simple daily meal checklist and a list of cheap local protein sources,
**So that** I eat consistently without the headache of calorie counting.

#### Acceptance Criteria
- **Scenario 10.1: Checking off daily meals**
  - **Given** I am on the eating checklist tab,
  - **When** I finish a meal,
  - **Then** I can tick: [x] وجبة الفطار [x] وجبة قبل الشغل [x] وجبة بعد الشغل [x] سناك بروتين [x] مياه كافية,
  - **And** checkmarks reset at midnight automatically.
- **Scenario 10.2: Cheap protein guide**
  - **Given** I want quick ideas for affordable protein in Egypt,
  - **When** I tap "أكلات بروتين اقتصادية",
  - **Then** a clean card displays local sources: بيض، كبدة، فول مدمس، جبنة قريش، عدس، علبة تونة، لبن، فول سوداني.

---

### US-11: Scheduled 3:30 PM Pre-Shift Reminder
**As a** user who wakes up around 3:00 PM and leaves for work at 5:00 PM,
**I want an** optional daily local reminder at 3:30 PM,
**So that** I remember to start my 20-minute session before getting ready for work.

#### Acceptance Criteria
- **Scenario 11.1: Local notification trigger**
  - **Given** reminders are enabled for 3:30 PM in Settings,
  - **When** the system clock reaches 3:30 PM,
  - **Then** a local Android notification arrives saying: "وقت تمرينك النهاردة يا بطل! 20 دقيقة بس قبل الشغل 💪",
  - **And** tapping the notification opens the Today screen directly.
- **Scenario 11.2: Notification toggle & quiet days**
  - **Given** I want to disable reminders on my days off,
  - **When** I go to Settings -> Reminders,
  - **Then** I can toggle notifications off or adjust the trigger time.

---

### US-12: Interrupted Workout Crash & App-Killed Resume
**As a** user whose phone might run out of battery or close the app mid-session,
**I want my** completed sets to be saved immediately,
**So that** I never lose workout data if Android terminates the process.

#### Acceptance Criteria
- **Scenario 12.1: Crash recovery**
  - **Given** I have completed 2 sets of Pull-ups and 1 set of Push-ups,
  - **When** Android OS kills the app due to memory pressure or the phone restarts,
  - **And** I reopen HOMESETS,
  - **Then** a prominent banner on the Today screen states: "عندك تمرين غير مكتمل — حابب تكمله؟",
  - **And** tapping "استئناف" restores the exact exercise, completed sets, and remaining movements.

---

### US-13: Single-File Local Backup & Validated Restore
**As a** user storing private progress photos and training history on my phone,
**I want to** export and import my complete data as a single backup file,
**So that** I can safeguard my data or transfer it to a new phone without relying on cloud servers.

#### Acceptance Criteria
- **Scenario 13.1: Exporting a backup archive**
  - **Given** I have 3 months of logs and 12 progress photos,
  - **When** I tap "تصدير نسخة احتياطية (Export Backup)" in Settings,
  - **Then** the app compiles database tables (JSON/SQLite) and private photos into a single compressed `.homesets` archive,
  - **And** prompts the Android system share sheet so I can save it locally or send it to my PC.
- **Scenario 13.2: Validated import**
  - **Given** I have a `.homesets` backup file,
  - **When** I select "استعادة نسخة احتياطية (Restore Backup)",
  - **Then** the app validates file checksum, schema compatibility, and image integrity,
  - **And** upon confirmation, restores all data and photos without corruption.

---

### US-14: Guilt-Free Return After Missed Training Days
**As a** user who was sick or overwhelmed for 10 days,
**I want the** app to welcome me back with a lighter re-entry workout,
**So that** I ease back in safely without muscle soreness or guilt over missed time.

#### Acceptance Criteria
- **Scenario 14.1: 7+ days absence handling**
  - **Given** 9 days have passed since my last completed workout,
  - **When** I open the Today screen,
  - **Then** the app displays: "حمد الله على السلامة! عشان بقالك فترة متمرنتش، جهزنالك تمرين خفيف لإعادة النشاط",
  - **And** reduces working set volume by 30–40% for the first 2 sessions before returning to full volume.

---

### US-15: Strict Offline Operation & Network Absence
**As a** privacy-conscious user training with mobile data turned off,
**I want the** app to function with 100% feature parity offline,
**So that** my fitness journey is completely autonomous, private, and zero-cost.

#### Acceptance Criteria
- **Scenario 15.1: Zero network dependency**
  - **Given** the phone is in Airplane Mode with Wi-Fi and Cellular data disabled,
  - **When** I perform onboarding, run workouts, log photos, inspect charts, and export backups,
  - **Then** every single feature operates without errors, warnings, or missing resources,
  - **And** AndroidManifest.xml contains NO `android.permission.INTERNET`.
