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
}
