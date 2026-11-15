import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/engine/workout_engine.dart';
import '../../data/repositories/workout_repository.dart';
import '../shared/tactile_card.dart';
import '../shared/kinetic_button.dart';
import '../shared/homesets_header.dart';
import '../../l10n/app_localizations.dart';

class TodayScreen extends StatefulWidget {
  final WorkoutRepository repository;
  final Function(ScheduledSession session, bool isResume) onStartWorkout;
  final VoidCallback onOpenSettings;

  const TodayScreen({
    super.key,
    required this.repository,
    required this.onStartWorkout,
    required this.onOpenSettings,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  UserProfile? _profile;
  ActiveSessionSnapshot? _activeSession;
  int _weeklyCredit = 0;
  bool _isLoading = true;

  ScheduledSession? _standardSession;
  ScheduledSession? _liteSession;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final profile = await widget.repository.getUserProfile();
    final inventory = await widget.repository.getEquipmentInventory();
    final activeSession = await widget.repository.getActiveSessionState();
    final credit = await widget.repository.getWeeklyConsistencyCredit();
    final lastWorkoutTime = await widget.repository.getLastWorkoutTime();
    final lastMuscleGroup = await widget.repository.getLastWorkoutMuscleGroup();
    final lastMuscleGroups = await widget.repository.getLastWorkoutTimePerMuscleGroup();
    final exerciseHistory = await widget.repository.getRecentExerciseHistory();
    final nextCycle = await widget.repository.getNextRoutineCycle();

    if (profile != null) {
      final engine = WorkoutEngine(inventory: inventory, profile: profile);
      _standardSession = engine.generateNextSession(
        routineCycle: nextCycle,
        lastWorkoutTime: lastWorkoutTime,
        lastTargetMuscleGroup: lastMuscleGroup,
        lastWorkoutTimePerGroup: lastMuscleGroups,
        exerciseHistory: exerciseHistory,
        isLiteMode: false,
      );
      _liteSession = engine.generateNextSession(
        routineCycle: nextCycle,
        lastWorkoutTime: lastWorkoutTime,
        lastTargetMuscleGroup: lastMuscleGroup,
        lastWorkoutTimePerGroup: lastMuscleGroups,
        exerciseHistory: exerciseHistory,
        isLiteMode: true,
      );
    }

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _activeSession = activeSession;
      _weeklyCredit = credit;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    if (_isLoading) {
      return const Scaffold(
        appBar: HomesetsHeader(),
        body: Center(
          child: CircularProgressIndicator(color: HomesetsColors.lime),
        ),
      );
    }

    return Scaffold(
      appBar: HomesetsHeader(
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: HomesetsColors.textSecondary),
            onPressed: widget.onOpenSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: HomesetsColors.lime,
          backgroundColor: HomesetsColors.surfaceElevated,
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Weekly Consistency Header Card
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: HomesetsColors.lime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.bolt, color: HomesetsColors.lime, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.weeklyProgress, style: HomesetsTypography.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            '$_weeklyCredit / ${_profile?.targetWorkoutsPerWeek ?? 4} ${isArabic ? "تمارين هذا الأسبوع" : "sessions this week"}',
                            style: HomesetsTypography.heading3.copyWith(color: HomesetsColors.lime),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Absence Deload Banner (C3R2 F5, D11, D15)
              if (_standardSession?.absenceDeloadResult != null &&
                  _standardSession!.absenceDeloadResult!.action != EngineAction.normalRotationResume) ...[
                TactileCard(
                  borderColor: HomesetsColors.lime,
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: HomesetsColors.lime, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'تعديل تدريجي للعودة بعد الغياب' : 'Gentle Re-entry Deload Active',
                              style: HomesetsTypography.heading3.copyWith(fontSize: 16, color: HomesetsColors.lime),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic
                                  ? 'تم تخفيف حجم التمرين بنسبة ${_standardSession!.absenceDeloadResult!.volumeReductionPercent}٪ لحماية الأوتار والمفاصل. لا توجد أي عقوبات على الاستمرارية.'
                                  : 'Volume is tapered by ${_standardSession!.absenceDeloadResult!.volumeReductionPercent}% to safely recondition tendons and joints. Zero streak penalties, zero guilt.',
                              style: HomesetsTypography.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 2. Active Interrupted Workout Banner (Crash Recovery WP22, F1, F2)
              if (_activeSession != null) ...[
                TactileCard(
                  isHighlighted: true,
                  borderColor: (_activeSession!.isPlanUnrecoverable || _activeSession!.scheduledSession == null)
                      ? HomesetsColors.orange
                      : HomesetsColors.lime,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            (_activeSession!.isPlanUnrecoverable || _activeSession!.scheduledSession == null)
                                ? Icons.warning_amber_rounded
                                : Icons.play_circle_fill,
                            color: (_activeSession!.isPlanUnrecoverable || _activeSession!.scheduledSession == null)
                                ? HomesetsColors.orange
                                : HomesetsColors.lime,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            (_activeSession!.isPlanUnrecoverable || _activeSession!.scheduledSession == null)
                                ? (isArabic ? 'مسودة تمرين تحتاج إجراء' : 'Draft Plan Unrecoverable')
                                : (isArabic ? 'تمرين قيد التقدم (محفوظ)' : 'In-Progress Workout (Recovered)'),
                            style: HomesetsTypography.tabularBadge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isArabic ? _activeSession!.routineNameAr : _activeSession!.routineName,
                        style: HomesetsTypography.heading2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'تم إكمال ${_activeSession!.completedSets.length} مجموعات محفوظة بأمان.'
                            : '${_activeSession!.completedSets.length} sets logged and safely preserved.',
                        style: HomesetsTypography.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      if (_activeSession!.isPendingFinalization) ...[
                        KineticButton(
                          label: isArabic ? 'إنهاء وحفظ التمرين المكتمل' : 'Finish & Finalize Workout',
                          icon: Icons.check_circle_outline,
                          onPressed: () async {
                            final now = DateTime.now();
                            final duration = now.difference(_activeSession!.startedAt).inSeconds;
                            final completed = CompletedWorkoutSession(
                              id: _activeSession!.sessionId,
                              scheduledSessionId: _activeSession!.sessionId,
                              routineName: _activeSession!.routineName,
                              isLiteMode: _activeSession!.isLiteMode,
                              startedAt: _activeSession!.startedAt,
                              endedAt: now,
                              totalDurationSeconds: duration > 0 ? duration : 60,
                              completedSets: _activeSession!.completedSets,
                              isEmergencyStopped: false,
                            );
                            await widget.repository.saveCompletedSession(completed);
                            await _loadData();
                          },
                        ),
                        const SizedBox(height: 8),
                      ] else if (_activeSession!.isPlanUnrecoverable ||
                          _activeSession!.scheduledSession == null ||
                          _activeSession!.scheduledSession!.exercises.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: HomesetsColors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: HomesetsColors.orange.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            _activeSession!.hasCorruptSetLogs
                                ? (isArabic
                                    ? 'تنبيه: مسودة التمرين تحتوي على بيانات تالفة جزئياً. تم استخراج ${_activeSession!.completedSets.length} مجموعة صالحة. سيتم أرشفة البيانات الأولية محلياً دون احتساب إنجاز غير مكتمل.'
                                    : 'Notice: Draft contains corrupt entries. ${_activeSession!.completedSets.length} valid sets extracted. Raw data will be durably archived in local storage without false completion credit.')
                                : (isArabic
                                    ? 'تنبيه: تعذر استعادة خطة التمرين الأصلية بأمان. تم العثور على ${_activeSession!.completedSets.length} مجموعة مسجلة وسيتم أرشفتها كجلسة جزئية.'
                                    : 'Notice: Original workout plan was unrecoverable. ${_activeSession!.completedSets.length} logged sets found and will be archived as a partial session.'),
                            style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.orange),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_activeSession!.completedSets.isNotEmpty) ...[
                          KineticButton(
                            label: _activeSession!.hasCorruptSetLogs
                                ? (isArabic ? 'أرشفة وحفظ المجموعات المستخرجة' : 'Archive Raw & Save Salvaged Sets')
                                : (isArabic ? 'أرشفة وحفظ المجموعات الجزئية' : 'Archive Raw & Save Partial Sets'),
                            icon: Icons.archive_outlined,
                            onPressed: () async {
                              final now = DateTime.now();
                              final duration = now.difference(_activeSession!.startedAt).inSeconds;
                              final completed = CompletedWorkoutSession(
                                id: _activeSession!.sessionId,
                                scheduledSessionId: _activeSession!.sessionId,
                                routineName: _activeSession!.routineName,
                                isLiteMode: _activeSession!.isLiteMode,
                                startedAt: _activeSession!.startedAt,
                                endedAt: now,
                                totalDurationSeconds: duration > 0 ? duration : 60,
                                completedSets: _activeSession!.completedSets,
                                isEmergencyStopped: true,
                                emergencyStopReason: _activeSession!.hasCorruptSetLogs
                                    ? 'Partial salvage from corrupt draft: raw logs archived (WP-A)'
                                    : 'Draft plan unrecoverable: raw logs archived (WP-A)',
                              );
                              await widget.repository.salvageCorruptSession(
                                session: completed,
                                rawCompletedSetsJson: _activeSession!.rawCompletedSetsJson,
                                rawActiveSessionJson: _activeSession!.rawActiveSessionJson,
                                hasCorruptSetLogs: _activeSession!.hasCorruptSetLogs,
                              );
                              await _loadData();
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                      ] else ...[
                        KineticButton(
                          label: isArabic ? 'استئناف التمرين' : 'Resume Workout',
                          icon: Icons.play_arrow,
                          onPressed: () {
                            widget.onStartWorkout(_activeSession!.scheduledSession!, true);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: HomesetsColors.textMuted,
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(
                            isArabic ? 'إلغاء المسودة المحفوظة' : 'Discard In-Progress Draft',
                            style: HomesetsTypography.bodySmall,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: HomesetsColors.surfaceElevated,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(
                                  isArabic ? 'إلغاء المسودة' : 'Discard Draft?',
                                  style: HomesetsTypography.heading3,
                                ),
                                content: Text(
                                  isArabic
                                      ? 'هل أنت متأكد من رغبتك في إلغاء هذا التمرين غير المكتمل؟ سيتم حذف التقدم المؤقت.'
                                      : 'Are you sure you want to discard this in-progress workout? Unfinished progress will be cleared.',
                                  style: HomesetsTypography.bodyMedium,
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: Text(isArabic ? 'تراجع' : 'Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: HomesetsColors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: Text(isArabic ? 'تأكيد الحذف' : 'Discard'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await widget.repository.clearActiveSessionState();
                              await _loadData();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // 3. Standard Routine Card
              if (_standardSession != null) ...[
                Text(l10n.todayTitle, style: HomesetsTypography.heading1),
                const SizedBox(height: 12),
                if (!_standardSession!.isViable) ...[
                  TactileCard(
                    borderColor: HomesetsColors.orange,
                    isHighlighted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.health_and_safety_outlined, color: HomesetsColors.orange, size: 24),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isArabic ? 'لا توجد تمارين متوافقة بأمان' : 'No Safe Exercises Available',
                                style: HomesetsTypography.heading3.copyWith(color: HomesetsColors.orange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isArabic
                              ? (_standardSession!.unviableReasonAr ?? 'جميع تمارين هذه الجولة تتطلب مفاصل مستبعدة أو أدوات غير متوفرة. سلامتك أولاً.')
                              : (_standardSession!.unviableReason ?? 'All movements for this routine require unavailable equipment or avoided joints. Your joint health comes first.'),
                          style: HomesetsTypography.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        KineticButton(
                          label: isArabic ? 'تعديل الأدوات والمفاصل' : 'Adjust Equipment & Joints',
                          icon: Icons.tune,
                          style: KineticButtonStyle.secondary,
                          onPressed: widget.onOpenSettings,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  TactileCard(
                    isHighlighted: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: HomesetsColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: HomesetsColors.borderSubtle),
                              ),
                              child: Text(
                                '~${_standardSession!.estimatedDurationMinutes} MIN',
                                style: HomesetsTypography.tabularBadge,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: HomesetsColors.lime.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                l10n.readyToTrain,
                                style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.lime),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isArabic ? _standardSession!.routineNameAr : _standardSession!.routineName,
                          style: HomesetsTypography.heading2,
                        ),
                        const SizedBox(height: 16),
                        // Exercise item previews
                        ..._standardSession!.exercises.map((pEx) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18, color: HomesetsColors.lime),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  isArabic ? pEx.exercise.nameAr : pEx.exercise.nameEn,
                                  style: HomesetsTypography.bodyMedium.copyWith(color: HomesetsColors.textPrimary),
                                ),
                              ),
                              Text(
                                '${pEx.sets.length}x${pEx.sets.first.targetMinReps}-${pEx.sets.first.targetMaxReps}',
                                style: HomesetsTypography.tabularBadge.copyWith(color: HomesetsColors.textSecondary),
                              ),
                            ],
                          ),
                        )),
                        const SizedBox(height: 20),
                        KineticButton(
                          label: l10n.startWorkout,
                          icon: Icons.play_arrow,
                          onPressed: () => widget.onStartWorkout(_standardSession!, false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],

              // 4. Adaptive Lite Mode Card (D12, D15, WP28)
              if (_liteSession != null && _liteSession!.isViable) ...[
                TactileCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.bolt, color: HomesetsColors.lime, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.liteModeHeading,
                              style: HomesetsTypography.heading3.copyWith(color: HomesetsColors.lime),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.liteModeSubtitle,
                        style: HomesetsTypography.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      KineticButton(
                        label: l10n.startLiteWorkout,
                        style: KineticButtonStyle.secondary,
                        onPressed: () => widget.onStartWorkout(_liteSession!, false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
