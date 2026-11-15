import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../domain/models/domain_models.dart';
import '../../data/repositories/workout_repository.dart';
import '../shared/tactile_card.dart';
import '../shared/kinetic_button.dart';
import '../shared/rep_counter_stepper.dart';
import '../../l10n/app_localizations.dart';

class WorkoutPlayerScreen extends StatefulWidget {
  final ScheduledSession session;
  final WorkoutRepository repository;
  final bool isResume;
  final Function(CompletedWorkoutSession completed) onFinishSession;
  final VoidCallback onQuit;

  const WorkoutPlayerScreen({
    super.key,
    required this.session,
    required this.repository,
    this.isResume = false,
    required this.onFinishSession,
    required this.onQuit,
  });

  @override
  State<WorkoutPlayerScreen> createState() => _WorkoutPlayerScreenState();
}

class _WorkoutPlayerScreenState extends State<WorkoutPlayerScreen> {
  int _exerciseIndex = 0;
  int _setIndex = 1;
  int _currentReps = 8;
  final List<SetLog> _completedSets = [];
  late DateTime _sessionStartTime;

  bool _isSessionFinished = false;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _initializeOrRestore();
  }

  Future<void> _initializeOrRestore() async {
    if (widget.isResume) {
      final snapshot = await widget.repository.getActiveSessionState();
      if (!mounted) return;
      if (snapshot != null) {
        setState(() {
          _exerciseIndex = snapshot.currentExerciseIndex.clamp(0, widget.session.exercises.length - 1);
          final maxSets = widget.session.exercises[_exerciseIndex].sets.length;
          _setIndex = snapshot.currentSetIndex.clamp(1, maxSets);
          _completedSets.addAll(snapshot.completedSets);
          _sessionStartTime = snapshot.startedAt;
        });
      }
    } else {
      // Save initial active session state snapshot (WP22)
      await widget.repository.saveActiveSessionState(ActiveSessionSnapshot(
        sessionId: widget.session.id,
        routineName: widget.session.routineName,
        routineNameAr: widget.session.routineNameAr,
        isLiteMode: widget.session.isLiteMode,
        startedAt: _sessionStartTime,
        currentExerciseIndex: 0,
        currentSetIndex: 1,
        completedSets: const [],
        scheduledSession: widget.session,
      ));
    }

    if (!mounted) return;
    if (_exerciseIndex < widget.session.exercises.length) {
      final currentEx = widget.session.exercises[_exerciseIndex];
      final safeSetIndex = (_setIndex - 1).clamp(0, currentEx.sets.length - 1);
      setState(() {
        _currentReps = currentEx.sets[safeSetIndex].targetMinReps;
      });
    }
  }

  PlannedExercise get _currentPlannedExercise => widget.session.exercises[_exerciseIndex];
  Exercise get _exercise => _currentPlannedExercise.exercise;
  int get _totalSetsInExercise => _currentPlannedExercise.sets.length;

  Future<void> _handleLogSet(ExertionRating exertion) async {
    if (_isSessionFinished) return;
    final now = DateTime.now();
    final log = SetLog(
      setIndex: _setIndex,
      exerciseId: _exercise.id,
      performedReps: _currentReps,
      exertion: exertion,
      completedAt: now,
    );

    setState(() {
      _completedSets.add(log);
    });

    // Compute boundary transitions for next set / next exercise
    final isLastSetOfExercise = _setIndex >= _totalSetsInExercise;
    final nextExerciseIndex = isLastSetOfExercise
        ? (_exerciseIndex + 1 < widget.session.exercises.length ? _exerciseIndex + 1 : _exerciseIndex)
        : _exerciseIndex;
    final nextSetIndex = isLastSetOfExercise ? 1 : _setIndex + 1;

    // Immediate write to active session snapshot (WP21, WP04 crash recovery)
    final snapshot = ActiveSessionSnapshot(
      sessionId: widget.session.id,
      routineName: widget.session.routineName,
      routineNameAr: widget.session.routineNameAr,
      isLiteMode: widget.session.isLiteMode,
      startedAt: _sessionStartTime,
      currentExerciseIndex: nextExerciseIndex,
      currentSetIndex: nextSetIndex,
      completedSets: List.unmodifiable(_completedSets),
      scheduledSession: widget.session,
    );
    await widget.repository.saveActiveSessionState(snapshot);
  }

  Future<void> _advanceAfterRest() async {
    if (_isSessionFinished) return;
    if (_setIndex < _totalSetsInExercise) {
      // Advance to next set in current exercise
      setState(() {
        _setIndex++;
        final safeSetIndex = (_setIndex - 1).clamp(0, _currentPlannedExercise.sets.length - 1);
        _currentReps = _currentPlannedExercise.sets[safeSetIndex].targetMinReps;
      });
    } else if (_exerciseIndex < widget.session.exercises.length - 1) {
      // Advance to next exercise
      setState(() {
        _exerciseIndex++;
        _setIndex = 1;
        _currentReps = widget.session.exercises[_exerciseIndex].sets.first.targetMinReps;
      });
    } else {
      // All exercises completed
      await _finalizeSession(isEmergency: false);
    }
  }

  Future<void> _finalizeSession({required bool isEmergency, String? reason}) async {
    _isSessionFinished = true;
    final now = DateTime.now();
    final durationSeconds = now.difference(_sessionStartTime).inSeconds;

    final completedSession = CompletedWorkoutSession(
      id: widget.session.id,
      scheduledSessionId: widget.session.id,
      routineName: widget.session.routineName,
      isLiteMode: widget.session.isLiteMode,
      startedAt: _sessionStartTime,
      endedAt: now,
      totalDurationSeconds: durationSeconds > 0 ? durationSeconds : 1,
      completedSets: List.unmodifiable(_completedSets),
      isEmergencyStopped: isEmergency,
      emergencyStopReason: reason,
    );

    await widget.repository.saveCompletedSession(completedSession);
    widget.onFinishSession(completedSession);
  }

  Future<void> _triggerPainStop() async {
    if (_isSessionFinished) return;
    _isSessionFinished = true;

    final now = DateTime.now();
    // 1. Immediately log the emergency pain stop set with 0 reps (C3R2 WP05)
    final painLog = SetLog(
      setIndex: _setIndex,
      exerciseId: _exercise.id,
      performedReps: 0,
      exertion: ExertionRating.painStopped,
      isPainStopped: true,
      painNote: 'Acute joint pain stop (SAFE-01, GOV14)',
      completedAt: now,
    );
    _completedSets.add(painLog);

    final durationSeconds = now.difference(_sessionStartTime).inSeconds;
    final completedSession = CompletedWorkoutSession(
      id: widget.session.id,
      scheduledSessionId: widget.session.id,
      routineName: widget.session.routineName,
      isLiteMode: widget.session.isLiteMode,
      startedAt: _sessionStartTime,
      endedAt: now,
      totalDurationSeconds: durationSeconds > 0 ? durationSeconds : 1,
      completedSets: List.unmodifiable(_completedSets),
      isEmergencyStopped: true,
      emergencyStopReason: 'Acute joint pain stop (SAFE-01)',
    );

    // 2. Quarantine joint(s) and finalize session durably (C3R-04, C3R2 F4)
    bool persistenceFailed = false;
    Future<bool> persistPainStop() async {
      try {
        final profile = await widget.repository.getUserProfile();
        if (profile != null && _exercise.jointStressTags.isNotEmpty) {
          final updatedAvoided = Set<JointImpactTag>.from(profile.avoidedJoints)
            ..addAll(_exercise.jointStressTags);
          await widget.repository.saveUserProfile(
            profile.copyWith(avoidedJoints: updatedAvoided.toList()),
          );
        }
        await widget.repository.saveCompletedSession(completedSession);
        return true;
      } catch (_) {
        persistenceFailed = true;
        return false;
      }
    }

    await persistPainStop();

    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // 3. Show the post-freeze informational safety dialog with retry on disk error (F4)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: HomesetsColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.shield, color: HomesetsColors.orange, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.painStopDialogTitle,
                  style: HomesetsTypography.heading3.copyWith(color: HomesetsColors.orange),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.painStopDialogBody,
                style: HomesetsTypography.bodyMedium,
              ),
              if (persistenceFailed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: HomesetsColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: HomesetsColors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: HomesetsColors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isArabic
                              ? 'تنبيه: تعذر حفظ استبعاد المفصل محلياً (خطأ قرص). اضغط إعادة المحاولة لحفظ السجل بأمان.'
                              : 'Notice: Could not save joint quarantine to local storage (Disk/IO error). Tap Retry Save.',
                          style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            if (persistenceFailed)
              TextButton(
                onPressed: () async {
                  final ok = await persistPainStop();
                  if (ok) {
                    setDialogState(() => persistenceFailed = false);
                  }
                },
                child: Text(isArabic ? 'إعادة محاولة الحفظ' : 'Retry Save'),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: HomesetsColors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onFinishSession(completedSession);
              },
              child: Text(l10n.painStopConfirm),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerQuitConfirm() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomesetsColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.quitDialogTitle, style: HomesetsTypography.heading3),
        content: Text(l10n.quitDialogBody, style: HomesetsTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.resumeWorkout),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: HomesetsColors.surfaceHighlight,
              foregroundColor: HomesetsColors.textPrimary,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onQuit();
            },
            child: Text(l10n.quitWorkout),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: HomesetsColors.textSecondary),
          onPressed: _triggerQuitConfirm,
        ),
        title: Text(
          isArabic ? widget.session.routineNameAr : widget.session.routineName,
          style: HomesetsTypography.heading3,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exercise Info Card
              TactileCard(
                isHighlighted: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.setCounter(_setIndex, _totalSetsInExercise),
                          style: HomesetsTypography.tabularBadge,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: HomesetsColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: HomesetsColors.borderSubtle),
                          ),
                          child: Text(
                            l10n.targetReps(
                              _currentPlannedExercise.sets.first.targetMinReps,
                              _currentPlannedExercise.sets.first.targetMaxReps,
                            ),
                            style: HomesetsTypography.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isArabic ? _exercise.nameAr : _exercise.nameEn,
                      style: HomesetsTypography.heading1.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isArabic ? _exercise.cuesAr : _exercise.cuesEn,
                      style: HomesetsTypography.bodySmall.copyWith(color: HomesetsColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Rep Counter Stepper
              Center(
                child: Text(
                  l10n.repsCompleted,
                  style: HomesetsTypography.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              RepCounterStepper(
                count: _currentReps,
                onChanged: (val) => setState(() => _currentReps = val),
              ),
              const Spacer(),

              // Primary Action: Log Set
              KineticButton(
                label: l10n.logSet,
                icon: Icons.check,
                onPressed: () async {
                  // Prompt exertion rating dialog
                  await _promptExertionAndRest();
                },
              ),
              const SizedBox(height: 12),

              // Emergency 1-Tap Pain STOP Button (SAFE-01)
              KineticButton(
                label: l10n.painStopButton,
                style: KineticButtonStyle.danger,
                onPressed: _triggerPainStop,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptExertionAndRest() async {
    final l10n = AppLocalizations.of(context)!;
    ExertionRating selected = ExertionRating.targetSweetspot;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      backgroundColor: HomesetsColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HomesetsColors.textMuted,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.effortPrompt,
                  style: HomesetsTypography.heading2,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Exertion options
                _ModalExertionTile(
                  title: l10n.effortSweetspot,
                  desc: l10n.effortSweetspotDesc,
                  color: HomesetsColors.lime,
                  isSelected: selected == ExertionRating.targetSweetspot,
                  onTap: () => setModalState(() => selected = ExertionRating.targetSweetspot),
                ),
                _ModalExertionTile(
                  title: l10n.effortEasy,
                  desc: l10n.effortEasyDesc,
                  color: HomesetsColors.success,
                  isSelected: selected == ExertionRating.easyReserve,
                  onTap: () => setModalState(() => selected = ExertionRating.easyReserve),
                ),
                _ModalExertionTile(
                  title: l10n.effortMax,
                  desc: l10n.effortMaxDesc,
                  color: HomesetsColors.orange,
                  isSelected: selected == ExertionRating.maxEffort,
                  onTap: () => setModalState(() => selected = ExertionRating.maxEffort),
                ),
                const SizedBox(height: 16),
                KineticButton(
                  label: l10n.logSet,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed == true) {
      if (_isSessionFinished) return;
      await _handleLogSet(selected);

      // Check if session is completely finished
      if (_setIndex >= _totalSetsInExercise && _exerciseIndex >= widget.session.exercises.length - 1) {
        await _finalizeSession(isEmergency: false);
        return;
      }

      // Transition to rest screen
      if (mounted && !_isSessionFinished) {
        final restDuration = _currentPlannedExercise.sets.first.targetRestSeconds;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => _RestTimerView(
              targetSeconds: restDuration,
              onFinished: () => Navigator.of(ctx).pop(),
            ),
          ),
        );
        if (_isSessionFinished) return;
        await _advanceAfterRest();
      }
    }
  }
}

class _ModalExertionTile extends StatelessWidget {
  final String title;
  final String desc;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModalExertionTile({
    required this.title,
    required this.desc,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? color.withValues(alpha: 0.15) : HomesetsColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: isSelected ? color : HomesetsColors.borderSubtle, width: isSelected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? color : HomesetsColors.textMuted,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: HomesetsTypography.heading3.copyWith(fontSize: 15, color: isSelected ? color : HomesetsColors.textPrimary)),
                      Text(desc, style: HomesetsTypography.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RestTimerView extends StatefulWidget {
  final int targetSeconds;
  final VoidCallback onFinished;

  const _RestTimerView({
    required this.targetSeconds,
    required this.onFinished,
  });

  @override
  State<_RestTimerView> createState() => _RestTimerViewState();
}

class _RestTimerViewState extends State<_RestTimerView> {
  late int _remaining;
  late int _total;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.targetSeconds;
    _total = widget.targetSeconds;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        timer.cancel();
        widget.onFinished();
      }
    });
  }

  void _addThirtySeconds() {
    setState(() {
      _remaining += 30;
      _total += 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.restTitle,
                style: HomesetsTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              RepaintBoundary(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _total > 0 ? (_remaining / _total).clamp(0.0, 1.0) : 0,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(HomesetsColors.lime),
                      ),
                      Text('$_remaining', style: HomesetsTypography.displayTimer),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              KineticButton(
                label: l10n.addThirtySeconds,
                style: KineticButtonStyle.secondary,
                icon: Icons.add,
                onPressed: _addThirtySeconds,
              ),
              const SizedBox(height: 12),
              KineticButton(
                label: l10n.skipRest,
                style: KineticButtonStyle.outline,
                onPressed: widget.onFinished,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
