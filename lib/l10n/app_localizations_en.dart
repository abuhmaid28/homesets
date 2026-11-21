// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HOMESETS';

  @override
  String get wordmark => 'HOMESETS';

  @override
  String get tagline => 'Private Calisthenics & Band Tracker';

  @override
  String get onboardingTitle => 'Set Up Your Training';

  @override
  String get onboardingSubtitle =>
      'Tailored for your equipment, schedule, and recovery.';

  @override
  String get goalTitle => 'Primary Focus';

  @override
  String get goalMuscleBuilding => 'Natural Muscle Growth & Strength';

  @override
  String get equipmentTitle => 'Available Hardware';

  @override
  String get pullUpBar => 'Doorway Pull-Up Bar';

  @override
  String get resistanceBands => 'Resistance Loop Bands';

  @override
  String get doorAnchor => 'Door Anchor Accessory';

  @override
  String get doorAnchorNote => 'Unchecked = Floor/bent-over exercises only';

  @override
  String get sturdyTable => 'Sturdy Heavy Table';

  @override
  String get sturdyTableNote => 'Solid wood for inverted rows';

  @override
  String get neutralGripAvailable => 'Parallel / Neutral Grip Handles';

  @override
  String get scheduleTitle => 'Shift Work Hours';

  @override
  String get wakeTimeLabel => 'Typical Wake Time';

  @override
  String get shiftStartLabel => 'Shift Start';

  @override
  String get targetWorkoutsLabel => 'Target Workouts per Week';

  @override
  String get fourSessionsPerWeek => '4 Sessions / Week (Recommended)';

  @override
  String get threeSessionsPerWeek => '3 Sessions / Week';

  @override
  String get saveAndContinue => 'Start Training';

  @override
  String get todayTitle => 'Today';

  @override
  String get nextSessionHeading => 'Next Up';

  @override
  String get estimatedTimeLabel => 'Estimated Time';

  @override
  String get liteModeHeading => '⚡ Quick Lite Mode (~15 min)';

  @override
  String get liteModeSubtitle => 'High-yield core sets for tired shift days';

  @override
  String get startWorkout => 'Start Workout';

  @override
  String get startLiteWorkout => 'Start Lite Workout';

  @override
  String get recoveryActiveNotice => 'Muscle Recovery in Progress';

  @override
  String get readyToTrain => 'Muscles Cleared & Ready';

  @override
  String get weeklyProgress => 'Weekly Consistency';

  @override
  String get activeWorkout => 'Active Workout';

  @override
  String setCounter(int current, int total) {
    return 'Set $current of $total';
  }

  @override
  String targetReps(int min, int max) {
    return 'Target: $min–$max reps';
  }

  @override
  String get repsCompleted => 'Reps Completed';

  @override
  String get logSet => 'Log Set & Rest';

  @override
  String get painStopButton => '🛑 Joint Discomfort / Pain Stop';

  @override
  String get painStopDialogTitle => 'Safety Priority: Stop Exercise';

  @override
  String get painStopDialogBody =>
      'Training through joint pain causes injury. Your logged sets are preserved, and this exercise will be quarantined from your upcoming sessions.';

  @override
  String get painStopConfirm => 'Stop Exercise Now';

  @override
  String get painStopCancel => 'Continue Set';

  @override
  String get restTitle => 'Rest Interval';

  @override
  String restSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get addThirtySeconds => '+30s Rest';

  @override
  String get skipRest => 'Skip Rest';

  @override
  String get effortPrompt => 'How did that set feel?';

  @override
  String get effortEasy => 'Easy Reserve 💪';

  @override
  String get effortEasyDesc => '3+ reps in reserve';

  @override
  String get effortSweetspot => 'Perfect Stimulus 👍';

  @override
  String get effortSweetspotDesc => '1–2 reps in reserve';

  @override
  String get effortMax => 'Max Effort 🔥';

  @override
  String get effortMaxDesc => '0 reps left in tank';

  @override
  String get summaryTitle => 'Session Complete';

  @override
  String get summarySubtitle =>
      'Solid effort. Recovery is where growth happens.';

  @override
  String get durationLabel => 'Total Duration';

  @override
  String get setsLoggedLabel => 'Sets Logged';

  @override
  String get consistencyAdded => '+1 Weekly Consistency Credit';

  @override
  String get finishWorkout => 'Back to Today';

  @override
  String get quitDialogTitle => 'Quit Workout?';

  @override
  String get quitDialogBody =>
      'Sets you have already logged will be saved. You can resume or start fresh later.';

  @override
  String get resumeWorkout => 'Resume Workout';

  @override
  String get quitWorkout => 'Save & Exit';

  @override
  String get navToday => 'Workout';

  @override
  String get navProgress => 'Progress';

  @override
  String get progressTitle => 'Progress Tracking';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabWeight => 'Weight';

  @override
  String get tabPhotos => 'Photos';

  @override
  String get tabStrength => 'Strength';

  @override
  String get tabMeals => 'Nutrition';

  @override
  String get currentWeight => 'Current Weight';

  @override
  String get rollingAverage => '7-Day Average';

  @override
  String get logWeight => 'Log Weight';

  @override
  String get enterWeightKg => 'Weight (kg)';

  @override
  String get saveWeight => 'Save Weight';

  @override
  String get weightHistory => 'Weight History';

  @override
  String get noWeightEntries => 'No weight entries logged yet';

  @override
  String get weightBoundsError => 'Weight must be between 30 and 300 kg';

  @override
  String get photosTitle => 'Physique Photos';

  @override
  String get addPhoto => 'Add Photo';

  @override
  String get comparePhotos => 'Compare';

  @override
  String get exitCompare => 'Done';

  @override
  String get selectTwoPhotos => 'Select 2 photos to compare side-by-side';

  @override
  String get frontAngle => 'Front';

  @override
  String get sideAngle => 'Side';

  @override
  String get backAngle => 'Back';

  @override
  String get allAngles => 'All';

  @override
  String get deletePhotoConfirmTitle => 'Delete Photo?';

  @override
  String get deletePhotoConfirmBody =>
      'This will permanently delete this photo from your private sandbox.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get noPhotos => 'No physique photos added yet';

  @override
  String get strengthTitle => 'Strength Progression';

  @override
  String get selectExercise => 'Select Exercise';

  @override
  String get noStrengthData => 'No completed strength sets yet';

  @override
  String get baselineLabel => 'Baseline';

  @override
  String get bestLabel => 'All-time Best';

  @override
  String get recentLabel => 'Recent';

  @override
  String repsDelta(int delta) {
    return '$delta reps vs baseline';
  }

  @override
  String get mealsTitle => 'Daily Protein Checklist';

  @override
  String get mealBreakfast => 'Breakfast';

  @override
  String get mealLunch => 'Lunch';

  @override
  String get mealDinner => 'Dinner';

  @override
  String get mealSnack1 => 'Snack 1 (Optional)';

  @override
  String get mealSnack2 => 'Snack 2 (Optional)';

  @override
  String get proteinHit => 'Protein goal met';

  @override
  String get proteinMiss => 'Not yet';

  @override
  String get proteinTipsTitle => 'Inexpensive Egyptian Protein Ideas';

  @override
  String get photoBefore => 'Before';

  @override
  String get photoAfter => 'After';

  @override
  String get editWeight => 'Edit Weight';

  @override
  String get appPrivateBadge => 'App-Private';

  @override
  String get bandFilterAll => 'All';

  @override
  String get bandFilterBodyweight => 'Bodyweight';

  @override
  String get saveFailed => 'Failed to save. Please try again.';

  @override
  String get deletePhotoFailed =>
      'Failed to delete photo from storage. Please try again.';

  @override
  String get deletePhotoDbFailed =>
      'Photo file removed, but database cleanup failed. Tap to retry.';

  @override
  String get retry => 'Retry';

  @override
  String get photoPendingCleanup =>
      'Photo file removed from storage. Database record pending removal.';

  @override
  String get privateStorageNotice =>
      'App-Private: Copied photos are kept in local offline app storage. Note: Originals in your device gallery or cloud backups are not managed by this app.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get profileEquipmentSettings => 'Equipment & Joint Profile';

  @override
  String get profileEquipmentSubtitle =>
      'Adjust pull-up bar, resistance bands, and joint safety preferences';

  @override
  String get editProfile => 'Edit Profile & Equipment';

  @override
  String get remindersSectionTitle => 'Daily Local Reminder';

  @override
  String get remindersToggle => 'Enable Workout Reminder';

  @override
  String get reminderTimeLabel => 'Reminder Time';

  @override
  String get changeTime => 'Change Time';

  @override
  String get reminderShameFreeDesc =>
      'A gentle daily nudge for your workout when it fits your shift, completely guilt-free.';

  @override
  String get notificationsDisabledWarning =>
      'Notifications are disabled in system settings. Enable notifications to receive daily reminders.';

  @override
  String get backupSectionTitle => 'Backup & Local Data';

  @override
  String get backupPrivacyNotice =>
      'Privacy Notice: The backup file includes your private progress photos, workout history, and personal logs. Store it safely and do not share it with untrusted parties.';

  @override
  String get createBackup => 'Create Offline Backup';

  @override
  String get creatingBackup => 'Packaging secure backup...';

  @override
  String get backupSuccess => 'Backup exported successfully.';

  @override
  String backupFailed(String error) {
    return 'Failed to create or export backup: $error';
  }

  @override
  String get restoreBackup => 'Restore from Backup';

  @override
  String get restoringBackup => 'Restoring backup data...';

  @override
  String get restoreSuccess => 'Data and photos restored successfully.';

  @override
  String restoreFailed(String error) {
    return 'Restore failed: $error';
  }

  @override
  String get restorePreviewTitle => 'Restore Backup Preview';

  @override
  String restoreCreatedAt(String date) {
    return 'Created: $date';
  }

  @override
  String restoreAppVersion(String version) {
    return 'App Version: $version';
  }

  @override
  String get restoreRecordCountsTitle => 'Archive Contents:';

  @override
  String restoreWorkoutsCount(int count) {
    return 'Workout Sessions: $count';
  }

  @override
  String restoreSetsCount(int count) {
    return 'Set Logs: $count';
  }

  @override
  String restoreWeightsCount(int count) {
    return 'Weight Logs: $count';
  }

  @override
  String restorePhotosCount(int count) {
    return 'Progress Photos: $count';
  }

  @override
  String get restoreDestructiveWarning =>
      'WARNING: Restoring will completely replace all existing workout logs, settings, and progress photos with the contents of this backup file. This action cannot be undone.';

  @override
  String get restoreConfirmButton => 'Replace Data & Restore';

  @override
  String get restoreCancelButton => 'Cancel';
}
