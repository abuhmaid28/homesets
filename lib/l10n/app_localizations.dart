import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HOMESETS'**
  String get appTitle;

  /// No description provided for @wordmark.
  ///
  /// In en, this message translates to:
  /// **'HOMESETS'**
  String get wordmark;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Private Calisthenics & Band Tracker'**
  String get tagline;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Up Your Training'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tailored for your equipment, schedule, and recovery.'**
  String get onboardingSubtitle;

  /// No description provided for @goalTitle.
  ///
  /// In en, this message translates to:
  /// **'Primary Focus'**
  String get goalTitle;

  /// No description provided for @goalMuscleBuilding.
  ///
  /// In en, this message translates to:
  /// **'Natural Muscle Growth & Strength'**
  String get goalMuscleBuilding;

  /// No description provided for @equipmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Hardware'**
  String get equipmentTitle;

  /// No description provided for @pullUpBar.
  ///
  /// In en, this message translates to:
  /// **'Doorway Pull-Up Bar'**
  String get pullUpBar;

  /// No description provided for @resistanceBands.
  ///
  /// In en, this message translates to:
  /// **'Resistance Loop Bands'**
  String get resistanceBands;

  /// No description provided for @doorAnchor.
  ///
  /// In en, this message translates to:
  /// **'Door Anchor Accessory'**
  String get doorAnchor;

  /// No description provided for @doorAnchorNote.
  ///
  /// In en, this message translates to:
  /// **'Unchecked = Floor/bent-over exercises only'**
  String get doorAnchorNote;

  /// No description provided for @sturdyTable.
  ///
  /// In en, this message translates to:
  /// **'Sturdy Heavy Table'**
  String get sturdyTable;

  /// No description provided for @sturdyTableNote.
  ///
  /// In en, this message translates to:
  /// **'Solid wood for inverted rows'**
  String get sturdyTableNote;

  /// No description provided for @neutralGripAvailable.
  ///
  /// In en, this message translates to:
  /// **'Parallel / Neutral Grip Handles'**
  String get neutralGripAvailable;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Shift Work Hours'**
  String get scheduleTitle;

  /// No description provided for @wakeTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Typical Wake Time'**
  String get wakeTimeLabel;

  /// No description provided for @shiftStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift Start'**
  String get shiftStartLabel;

  /// No description provided for @targetWorkoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Target Workouts per Week'**
  String get targetWorkoutsLabel;

  /// No description provided for @fourSessionsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'4 Sessions / Week (Recommended)'**
  String get fourSessionsPerWeek;

  /// No description provided for @threeSessionsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'3 Sessions / Week'**
  String get threeSessionsPerWeek;

  /// No description provided for @saveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Start Training'**
  String get saveAndContinue;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @nextSessionHeading.
  ///
  /// In en, this message translates to:
  /// **'Next Up'**
  String get nextSessionHeading;

  /// No description provided for @estimatedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTimeLabel;

  /// No description provided for @liteModeHeading.
  ///
  /// In en, this message translates to:
  /// **'⚡ Quick Lite Mode (~15 min)'**
  String get liteModeHeading;

  /// No description provided for @liteModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High-yield core sets for tired shift days'**
  String get liteModeSubtitle;

  /// No description provided for @startWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Workout'**
  String get startWorkout;

  /// No description provided for @startLiteWorkout.
  ///
  /// In en, this message translates to:
  /// **'Start Lite Workout'**
  String get startLiteWorkout;

  /// No description provided for @recoveryActiveNotice.
  ///
  /// In en, this message translates to:
  /// **'Muscle Recovery in Progress'**
  String get recoveryActiveNotice;

  /// No description provided for @readyToTrain.
  ///
  /// In en, this message translates to:
  /// **'Muscles Cleared & Ready'**
  String get readyToTrain;

  /// No description provided for @weeklyProgress.
  ///
  /// In en, this message translates to:
  /// **'Weekly Consistency'**
  String get weeklyProgress;

  /// No description provided for @activeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Active Workout'**
  String get activeWorkout;

  /// No description provided for @setCounter.
  ///
  /// In en, this message translates to:
  /// **'Set {current} of {total}'**
  String setCounter(int current, int total);

  /// No description provided for @targetReps.
  ///
  /// In en, this message translates to:
  /// **'Target: {min}–{max} reps'**
  String targetReps(int min, int max);

  /// No description provided for @repsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reps Completed'**
  String get repsCompleted;

  /// No description provided for @logSet.
  ///
  /// In en, this message translates to:
  /// **'Log Set & Rest'**
  String get logSet;

  /// No description provided for @painStopButton.
  ///
  /// In en, this message translates to:
  /// **'🛑 Joint Discomfort / Pain Stop'**
  String get painStopButton;

  /// No description provided for @painStopDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Safety Priority: Stop Exercise'**
  String get painStopDialogTitle;

  /// No description provided for @painStopDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Training through joint pain causes injury. Your logged sets are preserved, and this exercise will be quarantined from your upcoming sessions.'**
  String get painStopDialogBody;

  /// No description provided for @painStopConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop Exercise Now'**
  String get painStopConfirm;

  /// No description provided for @painStopCancel.
  ///
  /// In en, this message translates to:
  /// **'Continue Set'**
  String get painStopCancel;

  /// No description provided for @restTitle.
  ///
  /// In en, this message translates to:
  /// **'Rest Interval'**
  String get restTitle;

  /// No description provided for @restSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String restSeconds(int seconds);

  /// No description provided for @addThirtySeconds.
  ///
  /// In en, this message translates to:
  /// **'+30s Rest'**
  String get addThirtySeconds;

  /// No description provided for @skipRest.
  ///
  /// In en, this message translates to:
  /// **'Skip Rest'**
  String get skipRest;

  /// No description provided for @effortPrompt.
  ///
  /// In en, this message translates to:
  /// **'How did that set feel?'**
  String get effortPrompt;

  /// No description provided for @effortEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy Reserve 💪'**
  String get effortEasy;

  /// No description provided for @effortEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'3+ reps in reserve'**
  String get effortEasyDesc;

  /// No description provided for @effortSweetspot.
  ///
  /// In en, this message translates to:
  /// **'Perfect Stimulus 👍'**
  String get effortSweetspot;

  /// No description provided for @effortSweetspotDesc.
  ///
  /// In en, this message translates to:
  /// **'1–2 reps in reserve'**
  String get effortSweetspotDesc;

  /// No description provided for @effortMax.
  ///
  /// In en, this message translates to:
  /// **'Max Effort 🔥'**
  String get effortMax;

  /// No description provided for @effortMaxDesc.
  ///
  /// In en, this message translates to:
  /// **'0 reps left in tank'**
  String get effortMaxDesc;

  /// No description provided for @summaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get summaryTitle;

  /// No description provided for @summarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Solid effort. Recovery is where growth happens.'**
  String get summarySubtitle;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Duration'**
  String get durationLabel;

  /// No description provided for @setsLoggedLabel.
  ///
  /// In en, this message translates to:
  /// **'Sets Logged'**
  String get setsLoggedLabel;

  /// No description provided for @consistencyAdded.
  ///
  /// In en, this message translates to:
  /// **'+1 Weekly Consistency Credit'**
  String get consistencyAdded;

  /// No description provided for @finishWorkout.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get finishWorkout;

  /// No description provided for @quitDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Quit Workout?'**
  String get quitDialogTitle;

  /// No description provided for @quitDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Sets you have already logged will be saved. You can resume or start fresh later.'**
  String get quitDialogBody;

  /// No description provided for @resumeWorkout.
  ///
  /// In en, this message translates to:
  /// **'Resume Workout'**
  String get resumeWorkout;

  /// No description provided for @quitWorkout.
  ///
  /// In en, this message translates to:
  /// **'Save & Exit'**
  String get quitWorkout;

  /// No description provided for @navToday.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get navToday;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get navProgress;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress Tracking'**
  String get progressTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get tabWeight;

  /// No description provided for @tabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get tabPhotos;

  /// No description provided for @tabStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength'**
  String get tabStrength;

  /// No description provided for @tabMeals.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get tabMeals;

  /// No description provided for @currentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get currentWeight;

  /// No description provided for @rollingAverage.
  ///
  /// In en, this message translates to:
  /// **'7-Day Average'**
  String get rollingAverage;

  /// No description provided for @logWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get logWeight;

  /// No description provided for @enterWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get enterWeightKg;

  /// No description provided for @saveWeight.
  ///
  /// In en, this message translates to:
  /// **'Save Weight'**
  String get saveWeight;

  /// No description provided for @weightHistory.
  ///
  /// In en, this message translates to:
  /// **'Weight History'**
  String get weightHistory;

  /// No description provided for @noWeightEntries.
  ///
  /// In en, this message translates to:
  /// **'No weight entries logged yet'**
  String get noWeightEntries;

  /// No description provided for @weightBoundsError.
  ///
  /// In en, this message translates to:
  /// **'Weight must be between 30 and 300 kg'**
  String get weightBoundsError;

  /// No description provided for @photosTitle.
  ///
  /// In en, this message translates to:
  /// **'Physique Photos'**
  String get photosTitle;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get addPhoto;

  /// No description provided for @comparePhotos.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get comparePhotos;

  /// No description provided for @exitCompare.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get exitCompare;

  /// No description provided for @selectTwoPhotos.
  ///
  /// In en, this message translates to:
  /// **'Select 2 photos to compare side-by-side'**
  String get selectTwoPhotos;

  /// No description provided for @frontAngle.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get frontAngle;

  /// No description provided for @sideAngle.
  ///
  /// In en, this message translates to:
  /// **'Side'**
  String get sideAngle;

  /// No description provided for @backAngle.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backAngle;

  /// No description provided for @allAngles.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allAngles;

  /// No description provided for @deletePhotoConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Photo?'**
  String get deletePhotoConfirmTitle;

  /// No description provided for @deletePhotoConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this photo from your private sandbox.'**
  String get deletePhotoConfirmBody;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noPhotos.
  ///
  /// In en, this message translates to:
  /// **'No physique photos added yet'**
  String get noPhotos;

  /// No description provided for @strengthTitle.
  ///
  /// In en, this message translates to:
  /// **'Strength Progression'**
  String get strengthTitle;

  /// No description provided for @selectExercise.
  ///
  /// In en, this message translates to:
  /// **'Select Exercise'**
  String get selectExercise;

  /// No description provided for @noStrengthData.
  ///
  /// In en, this message translates to:
  /// **'No completed strength sets yet'**
  String get noStrengthData;

  /// No description provided for @baselineLabel.
  ///
  /// In en, this message translates to:
  /// **'Baseline'**
  String get baselineLabel;

  /// No description provided for @bestLabel.
  ///
  /// In en, this message translates to:
  /// **'All-time Best'**
  String get bestLabel;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @repsDelta.
  ///
  /// In en, this message translates to:
  /// **'{delta} reps vs baseline'**
  String repsDelta(int delta);

  /// No description provided for @mealsTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Protein Checklist'**
  String get mealsTitle;

  /// No description provided for @mealBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealBreakfast;

  /// No description provided for @mealLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealLunch;

  /// No description provided for @mealDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealDinner;

  /// No description provided for @mealSnack1.
  ///
  /// In en, this message translates to:
  /// **'Snack 1 (Optional)'**
  String get mealSnack1;

  /// No description provided for @mealSnack2.
  ///
  /// In en, this message translates to:
  /// **'Snack 2 (Optional)'**
  String get mealSnack2;

  /// No description provided for @proteinHit.
  ///
  /// In en, this message translates to:
  /// **'Protein goal met'**
  String get proteinHit;

  /// No description provided for @proteinMiss.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get proteinMiss;

  /// No description provided for @proteinTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Inexpensive Egyptian Protein Ideas'**
  String get proteinTipsTitle;

  /// No description provided for @photoBefore.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get photoBefore;

  /// No description provided for @photoAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get photoAfter;

  /// No description provided for @editWeight.
  ///
  /// In en, this message translates to:
  /// **'Edit Weight'**
  String get editWeight;

  /// No description provided for @appPrivateBadge.
  ///
  /// In en, this message translates to:
  /// **'App-Private'**
  String get appPrivateBadge;

  /// No description provided for @bandFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bandFilterAll;

  /// No description provided for @bandFilterBodyweight.
  ///
  /// In en, this message translates to:
  /// **'Bodyweight'**
  String get bandFilterBodyweight;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Please try again.'**
  String get saveFailed;

  /// No description provided for @deletePhotoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete photo from storage. Please try again.'**
  String get deletePhotoFailed;

  /// No description provided for @deletePhotoDbFailed.
  ///
  /// In en, this message translates to:
  /// **'Photo file removed, but database cleanup failed. Tap to retry.'**
  String get deletePhotoDbFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @photoPendingCleanup.
  ///
  /// In en, this message translates to:
  /// **'Photo file removed from storage. Database record pending removal.'**
  String get photoPendingCleanup;

  /// No description provided for @privateStorageNotice.
  ///
  /// In en, this message translates to:
  /// **'App-Private: Copied photos are kept in local offline app storage. Note: Originals in your device gallery or cloud backups are not managed by this app.'**
  String get privateStorageNotice;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @profileEquipmentSettings.
  ///
  /// In en, this message translates to:
  /// **'Equipment & Joint Profile'**
  String get profileEquipmentSettings;

  /// No description provided for @profileEquipmentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust pull-up bar, resistance bands, and joint safety preferences'**
  String get profileEquipmentSubtitle;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile & Equipment'**
  String get editProfile;

  /// No description provided for @remindersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Local Reminder'**
  String get remindersSectionTitle;

  /// No description provided for @remindersToggle.
  ///
  /// In en, this message translates to:
  /// **'Enable Workout Reminder'**
  String get remindersToggle;

  /// No description provided for @reminderTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTimeLabel;

  /// No description provided for @changeTime.
  ///
  /// In en, this message translates to:
  /// **'Change Time'**
  String get changeTime;

  /// No description provided for @reminderShameFreeDesc.
  ///
  /// In en, this message translates to:
  /// **'A gentle daily nudge for your workout when it fits your shift, completely guilt-free.'**
  String get reminderShameFreeDesc;

  /// No description provided for @notificationsDisabledWarning.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled in system settings. Enable notifications to receive daily reminders.'**
  String get notificationsDisabledWarning;

  /// No description provided for @backupSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Local Data'**
  String get backupSectionTitle;

  /// No description provided for @backupPrivacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice: The backup file includes your private progress photos, workout history, and personal logs. Store it safely and do not share it with untrusted parties.'**
  String get backupPrivacyNotice;

  /// No description provided for @createBackup.
  ///
  /// In en, this message translates to:
  /// **'Create Offline Backup'**
  String get createBackup;

  /// No description provided for @creatingBackup.
  ///
  /// In en, this message translates to:
  /// **'Packaging secure backup...'**
  String get creatingBackup;

  /// No description provided for @backupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully.'**
  String get backupSuccess;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create or export backup: {error}'**
  String backupFailed(String error);

  /// No description provided for @restoreBackup.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreBackup;

  /// No description provided for @restoringBackup.
  ///
  /// In en, this message translates to:
  /// **'Restoring backup data...'**
  String get restoringBackup;

  /// No description provided for @restoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data and photos restored successfully.'**
  String get restoreSuccess;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed: {error}'**
  String restoreFailed(String error);

  /// No description provided for @restorePreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup Preview'**
  String get restorePreviewTitle;

  /// No description provided for @restoreCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String restoreCreatedAt(String date);

  /// No description provided for @restoreAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version: {version}'**
  String restoreAppVersion(String version);

  /// No description provided for @restoreRecordCountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive Contents:'**
  String get restoreRecordCountsTitle;

  /// No description provided for @restoreWorkoutsCount.
  ///
  /// In en, this message translates to:
  /// **'Workout Sessions: {count}'**
  String restoreWorkoutsCount(int count);

  /// No description provided for @restoreSetsCount.
  ///
  /// In en, this message translates to:
  /// **'Set Logs: {count}'**
  String restoreSetsCount(int count);

  /// No description provided for @restoreWeightsCount.
  ///
  /// In en, this message translates to:
  /// **'Weight Logs: {count}'**
  String restoreWeightsCount(int count);

  /// No description provided for @restorePhotosCount.
  ///
  /// In en, this message translates to:
  /// **'Progress Photos: {count}'**
  String restorePhotosCount(int count);

  /// No description provided for @restoreDestructiveWarning.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Restoring will completely replace all existing workout logs, settings, and progress photos with the contents of this backup file. This action cannot be undone.'**
  String get restoreDestructiveWarning;

  /// No description provided for @restoreConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Replace Data & Restore'**
  String get restoreConfirmButton;

  /// No description provided for @restoreCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get restoreCancelButton;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
