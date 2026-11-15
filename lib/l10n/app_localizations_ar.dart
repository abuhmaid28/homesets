// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'هوم سيتس';

  @override
  String get wordmark => 'HOMESETS';

  @override
  String get tagline => 'تمرينك المنزلي بهدوء وبدون تعقيد';

  @override
  String get onboardingTitle => 'تجهيز خطة تمرينك';

  @override
  String get onboardingSubtitle =>
      'مصمم خصيصاً لأدواتك، وقت دوامك، واستشفاء عضلاتك.';

  @override
  String get goalTitle => 'الهدف الأساسي';

  @override
  String get goalMuscleBuilding => 'بناء عضل وزيادة قوة طبيعية';

  @override
  String get equipmentTitle => 'الأدوات المتوفرة عندك';

  @override
  String get pullUpBar => 'عقلة باب أو حائط';

  @override
  String get resistanceBands => 'أحبال مقاومة مطاطية';

  @override
  String get doorAnchor => 'ملحق تثبيت الباب للأحبال';

  @override
  String get doorAnchorNote => 'لو مش موجود = تمارين أرضية وسحب واقف فقط';

  @override
  String get sturdyTable => 'طاولة ثقيلة وخشب صلب';

  @override
  String get sturdyTableNote => 'لتمرين السحب العكسي بأمان';

  @override
  String get neutralGripAvailable => 'مقابض متوازية في العقلة';

  @override
  String get scheduleTitle => 'مواعيد الدوام والنوم';

  @override
  String get wakeTimeLabel => 'بتصحى الساعة كام تقريباً؟';

  @override
  String get shiftStartLabel => 'بداية الشيفت';

  @override
  String get targetWorkoutsLabel => 'هدف التمارين في الأسبوع';

  @override
  String get fourSessionsPerWeek => '٤ تمارين أسبوعياً (مثالي)';

  @override
  String get threeSessionsPerWeek => '٣ تمارين أسبوعياً';

  @override
  String get saveAndContinue => 'ابدأ على بركة الله';

  @override
  String get todayTitle => 'النهاردة';

  @override
  String get nextSessionHeading => 'تمرينك الجاي';

  @override
  String get estimatedTimeLabel => 'الوقت المتوقع';

  @override
  String get liteModeHeading => '⚡ تمرين سريع (~١٥ دقيقة)';

  @override
  String get liteModeSubtitle => 'تركيز على المجاميع الأساسية لأيام الإرهاق';

  @override
  String get startWorkout => 'ابدأ التمرين الكامل';

  @override
  String get startLiteWorkout => 'ابدأ التمرين السريع';

  @override
  String get recoveryActiveNotice => 'استشفاء العضلات جاري';

  @override
  String get readyToTrain => 'العضلات جاهزة ومرتاحة';

  @override
  String get weeklyProgress => 'الاستمرارية الأسبوعية';

  @override
  String get activeWorkout => 'التمرين شغال';

  @override
  String setCounter(int current, int total) {
    return 'مجموعة $current من $total';
  }

  @override
  String targetReps(int min, int max) {
    return 'الهدف: $min–$max عدات';
  }

  @override
  String get repsCompleted => 'جبت كام عدة؟';

  @override
  String get logSet => 'تسجيل المجموعة وبدء الراحة';

  @override
  String get painStopButton => '🛑 ألم أو انزعاج مفصلي (وقف التمرين)';

  @override
  String get painStopDialogTitle => 'سلامة مفاصلك أولاً';

  @override
  String get painStopDialogBody =>
      'التمرين على وجع المفاصل بيسبب إصابات. مجموعاتك اللي عملتها مسجلة ومحفوظة، والتمرين ده هيتم استبعاده تلقائياً من الجولات القادمة.';

  @override
  String get painStopConfirm => 'وقف التمرين فوراً';

  @override
  String get painStopCancel => 'إلغاء ومتابعة المجموعة';

  @override
  String get restTitle => 'وقت الراحة والاستشفاء';

  @override
  String restSeconds(int seconds) {
    return '$seconds ثانية';
  }

  @override
  String get addThirtySeconds => '+٣٠ ثانية راحة إضافية';

  @override
  String get skipRest => 'جاهز، عدي الراحة';

  @override
  String get effortPrompt => 'حسيت بالمجموعة إزاي؟';

  @override
  String get effortEasy => 'فاضل طاقة (سهل) 💪';

  @override
  String get effortEasyDesc => 'كان ممكن تجيب ٣ عدات كمان أو أكتر';

  @override
  String get effortSweetspot => 'مظبوط ومثالي 👍';

  @override
  String get effortSweetspotDesc =>
      'فاضل عدة أو اتنين في التانك (التحفيز المطلوب)';

  @override
  String get effortMax => 'على الآخر (أقصى مجهود) 🔥';

  @override
  String get effortMaxDesc => 'جبت آخرك بالظبط بصعوبة';

  @override
  String get summaryTitle => 'عاش يا بطل! خلصت التمرين';

  @override
  String get summarySubtitle =>
      'مجهود ممتاز. العضلات بتكبر في وقت الراحة والأكل الصح.';

  @override
  String get durationLabel => 'مدة التمرين الفعلي';

  @override
  String get setsLoggedLabel => 'المجاميع المسجلة';

  @override
  String get consistencyAdded => '+١ لرصيد التزامك الأسبوعي';

  @override
  String get finishWorkout => 'رجوع للرئيسية';

  @override
  String get quitDialogTitle => 'تأكيد إنهاء التمرين؟';

  @override
  String get quitDialogBody =>
      'المجموعات اللي سجلتها هتفضل محفوظة في سجلاتك. تقدر تكمل في أي وقت.';

  @override
  String get resumeWorkout => 'متابعة التمرين';

  @override
  String get quitWorkout => 'حفظ وخروج';

  @override
  String get navToday => 'التمرين';

  @override
  String get navProgress => 'التطور';

  @override
  String get progressTitle => 'متابعة التطور والنتائج';

  @override
  String get tabOverview => 'نظرة عامة';

  @override
  String get tabWeight => 'الوزن';

  @override
  String get tabPhotos => 'الصور';

  @override
  String get tabStrength => 'القوة';

  @override
  String get tabMeals => 'التغذية';

  @override
  String get currentWeight => 'الوزن الحالي';

  @override
  String get rollingAverage => 'متوسط ٧ أيام';

  @override
  String get logWeight => 'تسجيل الوزن';

  @override
  String get enterWeightKg => 'الوزن (كجم)';

  @override
  String get saveWeight => 'حفظ الوزن';

  @override
  String get weightHistory => 'سجل الوزن';

  @override
  String get noWeightEntries => 'لم تسجل أي وزن حتى الآن';

  @override
  String get weightBoundsError => 'الوزن يجب أن يكون بين ٣٠ و ٣٠٠ كجم';

  @override
  String get photosTitle => 'صور الجسم والتطور';

  @override
  String get addPhoto => 'إضافة صورة';

  @override
  String get comparePhotos => 'مقارنة صورتين';

  @override
  String get exitCompare => 'تم';

  @override
  String get selectTwoPhotos => 'اختر صورتين للمقارنة جنباً لجنب';

  @override
  String get frontAngle => 'أمام';

  @override
  String get sideAngle => 'جانب';

  @override
  String get backAngle => 'خلف';

  @override
  String get allAngles => 'الكل';

  @override
  String get deletePhotoConfirmTitle => 'حذف الصورة؟';

  @override
  String get deletePhotoConfirmBody =>
      'سيتم مسح هذه الصورة نهائياً من مساحة التطبيق الخاصة.';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String get noPhotos => 'لم تقم بإضافة أي صور بعد';

  @override
  String get strengthTitle => 'تطور القوة والمجاميع';

  @override
  String get selectExercise => 'اختر التمرين';

  @override
  String get noStrengthData => 'لم تسجل مجاميع قوة مكتملة بعد';

  @override
  String get baselineLabel => 'البداية';

  @override
  String get bestLabel => 'أفضل أداء';

  @override
  String get recentLabel => 'آخر تمرين';

  @override
  String repsDelta(int delta) {
    return '$delta عدة مقارنة بالبداية';
  }

  @override
  String get mealsTitle => 'متابعة البروتين اليومي';

  @override
  String get mealBreakfast => 'الفطار';

  @override
  String get mealLunch => 'الغداء';

  @override
  String get mealDinner => 'العشاء';

  @override
  String get mealSnack1 => 'سناك ١ (اختياري)';

  @override
  String get mealSnack2 => 'سناك ٢ (اختياري)';

  @override
  String get proteinHit => 'تم تحقيق هدف البروتين';

  @override
  String get proteinMiss => 'لم يتحقق بعد';

  @override
  String get proteinTipsTitle => 'أفكار بروتين اقتصادية وسريعة';

  @override
  String get photoBefore => 'قبل';

  @override
  String get photoAfter => 'بعد';

  @override
  String get privateStorageNotice =>
      '🔒 خصوصية تامة: الصور محفوظة داخل مساحة التطبيق ولا تخرج أبداً';
}
