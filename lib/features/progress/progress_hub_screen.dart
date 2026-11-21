import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/homesets_colors.dart';
import '../../core/theme/homesets_typography.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/services/photo_service.dart';
import '../../domain/models/domain_models.dart';
import '../../domain/progress/progress_analytics.dart';
import '../../l10n/app_localizations.dart';
import '../shared/tactile_card.dart';
import '../shared/kinetic_button.dart';
import 'widgets/log_weight_dialog.dart';
import 'widgets/meal_checklist_card.dart';
import 'widgets/photo_comparison_view.dart';
import 'widgets/progress_charts.dart';

/// Central Hub for Progress Tracking (P5, WP09, WP10).
/// Integrates private physique photos, body weight, strength curves, and nutrition.
class ProgressHubScreen extends StatefulWidget {
  final WorkoutRepository repository;
  final PhotoService photoService;
  final DateTime Function()? nowProvider;

  const ProgressHubScreen({
    super.key,
    required this.repository,
    required this.photoService,
    this.nowProvider,
  });

  @override
  State<ProgressHubScreen> createState() => _ProgressHubScreenState();
}

class _ProgressHubScreenState extends State<ProgressHubScreen> with WidgetsBindingObserver {
  int _selectedTab = 0; // 0=Overview, 1=Weight, 2=Photos, 3=Strength, 4=Meals
  bool _isLoading = true;

  // Weight state
  List<WeightEntry> _weightEntries = [];
  double? _rollingAverage;

  // Photos state
  List<ProgressPhoto> _photos = [];
  PhotoAngle? _photoAngleFilter;
  bool _isCompareMode = false;
  final List<ProgressPhoto> _selectedForCompare = [];
  bool _isShowingComparison = false;

  // Strength state (WP04, P5-R05)
  List<String> _exerciseIds = [];
  String? _selectedExerciseId;
  List<String> _availableBands = [];
  String? _selectedBandFilter;
  List<StrengthDataPoint> _strengthPoints = [];
  StrengthSummary? _strengthSummary;

  // Meal state (WP06, P5-R07)
  final Map<int, bool> _todayMealChecks = {};
  late String _todayYmd;

  // Consistency credit
  int _weeklyCredit = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _todayYmd = _currentDateYmd();
    _loadAllData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Calculates dynamic calendar date string YYYY-MM-DD.
  String _currentDateYmd() {
    final now = widget.nowProvider != null ? widget.nowProvider!() : DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// P5-R07: Midnight rollover handling when app is resumed from background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final currentYmd = _currentDateYmd();
      if (_todayYmd != currentYmd) {
        setState(() => _todayYmd = currentYmd);
        _loadAllData();
      }
    }
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final weights = await widget.repository.getWeightEntries();
      final rollingAvg = ProgressAnalytics.calculateRolling7DayAverage(weights, DateTime.now());
      final photos = await widget.repository.getProgressPhotos();

      final exerciseIds = await widget.repository.getLoggedExerciseIds();
      final credit = await widget.repository.getWeeklyConsistencyCredit();

      String? activeExercise = _selectedExerciseId;
      if (activeExercise == null || !exerciseIds.contains(activeExercise)) {
        activeExercise = exerciseIds.isNotEmpty ? exerciseIds.first : null;
      }

      List<StrengthDataPoint> points = [];
      StrengthSummary? summary;
      List<String> availableBands = [];
      if (activeExercise != null) {
        availableBands = await widget.repository.getAvailableBandConfigurations(activeExercise);
        if (_selectedBandFilter != null && !availableBands.contains(_selectedBandFilter) && _selectedBandFilter != 'all') {
          _selectedBandFilter = null;
        }
        points = await widget.repository.getStrengthHistoryForExercise(
          activeExercise,
          bandFilter: _selectedBandFilter,
        );
        summary = ProgressAnalytics.computeStrengthSummary(points);
      }

      final mealMap = await widget.repository.getMealChecksForDate(_todayYmd);

      if (!mounted) return;
      setState(() {
        _weightEntries = weights;
        _rollingAverage = rollingAvg;
        _photos = photos;
        _exerciseIds = exerciseIds;
        _selectedExerciseId = activeExercise;
        _availableBands = availableBands;
        _strengthPoints = points;
        _strengthSummary = summary;
        _todayMealChecks
          ..clear()
          ..addAll(mealMap);
        _weeklyCredit = credit;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSelectExercise(String? exerciseId) async {
    if (exerciseId == null || exerciseId == _selectedExerciseId) return;
    _selectedBandFilter = null; // P5-FINAL-05: Reset stale configuration filter before query
    final bands = await widget.repository.getAvailableBandConfigurations(exerciseId);
    final points = await widget.repository.getStrengthHistoryForExercise(
      exerciseId,
      bandFilter: null,
    );
    final summary = ProgressAnalytics.computeStrengthSummary(points);
    if (!mounted) return;
    setState(() {
      _selectedExerciseId = exerciseId;
      _selectedBandFilter = null;
      _availableBands = bands;
      _strengthPoints = points;
      _strengthSummary = summary;
    });
  }

  Future<void> _onSelectBandFilter(String? band) async {
    if (band == _selectedBandFilter) return;
    setState(() => _selectedBandFilter = band);
    if (_selectedExerciseId != null) {
      final points = await widget.repository.getStrengthHistoryForExercise(
        _selectedExerciseId!,
        bandFilter: band,
      );
      final summary = ProgressAnalytics.computeStrengthSummary(points);
      if (!mounted) return;
      setState(() {
        _strengthPoints = points;
        _strengthSummary = summary;
      });
    }
  }

  Future<void> _onLogWeightPrompt() async {
    final latestWeight = _weightEntries.isNotEmpty ? _weightEntries.first.weightKg : null;
    await showDialog(
      context: context,
      builder: (ctx) => LogWeightDialog(
        initialWeight: latestWeight,
        onSaveAsync: (val) async {
          final now = DateTime.now();
          final entry = WeightEntry(
            id: 'wt_${now.millisecondsSinceEpoch}',
            weightKg: val,
            loggedAt: now,
          );
          await widget.repository.saveWeightEntry(entry);
          await _loadAllData();
        },
      ),
    );
  }

  Future<void> _onEditWeightPrompt(WeightEntry entry) async {
    await showDialog(
      context: context,
      builder: (ctx) => LogWeightDialog(
        entryToEdit: entry,
        onSaveAsync: (val) async {
          final updated = WeightEntry(
            id: entry.id,
            weightKg: val,
            loggedAt: entry.loggedAt,
            notes: entry.notes,
          );
          await widget.repository.saveWeightEntry(updated);
          await _loadAllData();
        },
      ),
    );
  }

  Future<void> _onDeleteWeight(WeightEntry entry) async {
    await widget.repository.deleteWeightEntry(entry.id);
    await _loadAllData();
  }

  Future<void> _onToggleMeal(int slot, bool rawIsChecked) async {
    // P5-FINAL-03: Rollover check before toggling
    final currentYmd = _currentDateYmd();
    if (_todayYmd != currentYmd) {
      setState(() => _todayYmd = currentYmd);
      await _loadAllData();
      // User tapped on stale widget from yesterday.
      // Toggle today's fresh actual state:
      final newCheckedState = !(_todayMealChecks[slot] ?? false);
      await widget.repository.saveMealCheck(_todayYmd, slot, newCheckedState);
      if (mounted) {
        setState(() {
          _todayMealChecks[slot] = newCheckedState;
        });
      }
      return;
    }

    await widget.repository.saveMealCheck(_todayYmd, slot, rawIsChecked);
    if (mounted) {
      setState(() {
        _todayMealChecks[slot] = rawIsChecked;
      });
    }
  }

  Future<void> _onAddPhotoPrompt() async {
    final l10n = AppLocalizations.of(context)!;
    final angle = await showModalBottomSheet<PhotoAngle>(
      context: context,
      backgroundColor: HomesetsColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.photosTitle,
                style: HomesetsTypography.heading2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person, color: HomesetsColors.lime),
                title: Text(l10n.frontAngle, style: HomesetsTypography.bodyLarge),
                onTap: () => Navigator.of(ctx).pop(PhotoAngle.front),
              ),
              ListTile(
                leading: const Icon(Icons.accessibility_new, color: HomesetsColors.lime),
                title: Text(l10n.sideAngle, style: HomesetsTypography.bodyLarge),
                onTap: () => Navigator.of(ctx).pop(PhotoAngle.side),
              ),
              ListTile(
                leading: const Icon(Icons.airline_seat_recline_normal, color: HomesetsColors.lime),
                title: Text(l10n.backAngle, style: HomesetsTypography.bodyLarge),
                onTap: () => Navigator.of(ctx).pop(PhotoAngle.back),
              ),
            ],
          ),
        ),
      ),
    );

    if (angle == null) return;

    final stagedPath = await widget.photoService.pickPhotoFromGallery();
    if (stagedPath == null) return;

    final photoId = 'photo_${DateTime.now().millisecondsSinceEpoch}';
    String privateRelativePath;
    try {
      privateRelativePath =
          await widget.photoService.copyToPrivateSandbox(stagedPath, photoId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed)),
        );
      }
      return;
    }

    final photo = ProgressPhoto(
      id: photoId,
      filePath: privateRelativePath,
      angle: angle,
      takenAt: DateTime.now(),
    );

    try {
      await widget.repository.saveProgressPhoto(photo);
      widget.photoService.completePendingImport(privateRelativePath);
    } catch (e) {
      widget.photoService.completePendingImport(privateRelativePath);
      // P5-R02: Compensating rollback — remove sandbox file immediately to avoid orphan
      try {
        await widget.photoService.deletePrivatePhoto(privateRelativePath);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.saveFailed)),
        );
      }
      return;
    }
    await _loadAllData();
  }

  Future<void> _onDeletePhotoPrompt(ProgressPhoto photo, {bool skipConfirmation = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = skipConfirmation
        ? true
        : await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: HomesetsColors.surfaceCard,
              title: Text(l10n.deletePhotoConfirmTitle, style: HomesetsTypography.heading2),
              content: Text(l10n.deletePhotoConfirmBody, style: HomesetsTypography.bodyMedium),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(l10n.cancel, style: const TextStyle(color: HomesetsColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HomesetsColors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );

    if (confirmed == true) {
      bool fileDeleted = false;
      try {
        fileDeleted = await widget.photoService.deletePrivatePhoto(photo.filePath);
      } catch (_) {
        fileDeleted = false;
      }

      if (!fileDeleted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deletePhotoFailed),
              backgroundColor: HomesetsColors.orange,
            ),
          );
        }
        return;
      }

      try {
        await widget.repository.deleteProgressPhoto(photo.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.deletePhotoDbFailed),
              backgroundColor: HomesetsColors.orange,
              action: SnackBarAction(
                label: l10n.retry,
                textColor: Colors.white,
                onPressed: () => _onDeletePhotoPrompt(photo, skipConfirmation: true),
              ),
            ),
          );
        }
        await _loadAllData();
        return;
      }

      setState(() {
        _selectedForCompare.removeWhere((p) => p.id == photo.id);
      });
      await _loadAllData();
    }
  }

  void _togglePhotoSelectionForCompare(ProgressPhoto photo) {
    setState(() {
      if (_selectedForCompare.any((p) => p.id == photo.id)) {
        _selectedForCompare.removeWhere((p) => p.id == photo.id);
      } else {
        if (_selectedForCompare.length >= 2) {
          _selectedForCompare.removeAt(0);
        }
        _selectedForCompare.add(photo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (_isShowingComparison && _selectedForCompare.length == 2) {
      return Scaffold(
        body: PhotoComparisonView(
          photoBefore: _selectedForCompare[0].takenAt.isBefore(_selectedForCompare[1].takenAt)
              ? _selectedForCompare[0]
              : _selectedForCompare[1],
          photoAfter: _selectedForCompare[0].takenAt.isBefore(_selectedForCompare[1].takenAt)
              ? _selectedForCompare[1]
              : _selectedForCompare[0],
          photoService: widget.photoService,
          onClose: () => setState(() => _isShowingComparison = false),
        ),
      );
    }

    return Scaffold(
      backgroundColor: HomesetsColors.background,
      appBar: AppBar(
        title: Text(l10n.progressTitle, style: HomesetsTypography.heading2),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: HomesetsColors.surfaceCard,
                    title: Text(l10n.appPrivateBadge, style: HomesetsTypography.heading2),
                    content: Text(l10n.privateStorageNotice, style: HomesetsTypography.bodyMedium),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.cancel),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HomesetsColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: HomesetsColors.borderSubtle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 12, color: HomesetsColors.lime),
                    const SizedBox(width: 4),
                    Text(
                      l10n.appPrivateBadge,
                      style: const TextStyle(
                        fontSize: 10,
                        color: HomesetsColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: Column(
                children: [
                  _buildSubTabBar(l10n),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: _buildSelectedTabContent(l10n),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSubTabBar(AppLocalizations l10n) {
    final tabs = [
      (0, l10n.tabOverview, Icons.dashboard_outlined),
      (1, l10n.tabWeight, Icons.monitor_weight_outlined),
      (2, l10n.tabPhotos, Icons.photo_camera_outlined),
      (3, l10n.tabStrength, Icons.fitness_center_outlined),
      (4, l10n.tabMeals, Icons.restaurant_outlined),
    ];

    return Container(
      color: HomesetsColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isSelected = _selectedTab == t.$1;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                key: Key('tab_chip_${t.$1}'),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 16,
                      color: isSelected
                          ? HomesetsColors.textOnLime
                          : HomesetsColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(t.$2),
                  ],
                ),
                selected: isSelected,
                selectedColor: HomesetsColors.lime,
                backgroundColor: HomesetsColors.surfaceElevated,
                labelStyle: TextStyle(
                  color: isSelected
                      ? HomesetsColors.textOnLime
                      : HomesetsColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: isSelected
                      ? HomesetsColors.lime
                      : HomesetsColors.borderSubtle,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _selectedTab = t.$1);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(AppLocalizations l10n) {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab(l10n);
      case 1:
        return _buildWeightTab(l10n);
      case 2:
        return _buildPhotosTab(l10n);
      case 3:
        return _buildStrengthTab(l10n);
      case 4:
        return _buildMealsTab(l10n);
      default:
        return _buildOverviewTab(l10n);
    }
  }

  Widget _buildOverviewTab(AppLocalizations l10n) {
    final latestWeight =
        _weightEntries.isNotEmpty ? _weightEntries.first.weightKg : null;

    int mealsChecked = 0;
    for (final k in [0, 1, 2]) {
      if (_todayMealChecks[k] == true) mealsChecked++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Metrics Grid
        Row(
          children: [
            Expanded(
              child: TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.currentWeight, style: HomesetsTypography.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      latestWeight != null
                          ? '${latestWeight.toStringAsFixed(1)} kg'
                          : '--',
                      style: HomesetsTypography.heading1.copyWith(
                        color: HomesetsColors.lime,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    if (_rollingAverage != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Avg: ${_rollingAverage!.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          color: HomesetsColors.textSecondary,
                          fontSize: 11,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.weeklyProgress, style: HomesetsTypography.bodySmall),
                    const SizedBox(height: 6),
                    Text(
                      '$_weeklyCredit / 4',
                      style: HomesetsTypography.heading1.copyWith(
                        color: _weeklyCredit >= 4
                            ? HomesetsColors.lime
                            : HomesetsColors.textPrimary,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Today\'s Meals: $mealsChecked/3',
                      style: const TextStyle(
                        color: HomesetsColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Body Weight Trend Card
        TactileCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(l10n.tabWeight, style: HomesetsTypography.heading3),
                  TextButton.icon(
                    onPressed: _onLogWeightPrompt,
                    icon: const Icon(Icons.add, size: 16, color: HomesetsColors.lime),
                    label: Text(l10n.logWeight,
                        style: const TextStyle(color: HomesetsColors.lime, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_weightEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      l10n.noWeightEntries,
                      style: const TextStyle(color: HomesetsColors.textMuted),
                    ),
                  ),
                )
              else
                WeightTrendChart(
                  entries: _weightEntries,
                  rollingAverage: _rollingAverage,
                  height: 140,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Recent Photos Strip Card
        TactileCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(l10n.photosTitle, style: HomesetsTypography.heading3),
                  TextButton.icon(
                    onPressed: _onAddPhotoPrompt,
                    icon: const Icon(Icons.camera_alt_outlined, size: 16, color: HomesetsColors.lime),
                    label: Text(l10n.addPhoto,
                        style: const TextStyle(color: HomesetsColors.lime, fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_photos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      l10n.noPhotos,
                      style: const TextStyle(color: HomesetsColors.textMuted),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (ctx, idx) => _buildPhotoThumbnailTile(_photos[idx]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Privacy banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: HomesetsColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomesetsColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, color: HomesetsColors.lime, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.privateStorageNotice,
                  style: const TextStyle(
                    color: HomesetsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightTab(AppLocalizations l10n) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KineticButton(
          key: const Key('log_weight_main_btn'),
          label: l10n.logWeight,
          icon: Icons.add,
          onPressed: _onLogWeightPrompt,
        ),
        const SizedBox(height: 16),
        TactileCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(l10n.weightHistory, style: HomesetsTypography.heading3),
                  if (_rollingAverage != null)
                    Text(
                      '${l10n.rollingAverage}: ${_rollingAverage!.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: HomesetsColors.lime,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_weightEntries.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(l10n.noWeightEntries,
                        style: const TextStyle(color: HomesetsColors.textMuted)),
                  ),
                )
              else ...[
                WeightTrendChart(
                  entries: _weightEntries,
                  rollingAverage: _rollingAverage,
                  height: 180,
                ),
                const SizedBox(height: 16),
                const Divider(color: HomesetsColors.borderSubtle),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _weightEntries.length,
                  separatorBuilder: (_, _) =>
                      const Divider(color: HomesetsColors.borderSubtle, height: 1),
                  itemBuilder: (ctx, i) {
                    final e = _weightEntries[i];
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => _onEditWeightPrompt(e),
                        title: Text(
                          '${e.weightKg.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            color: HomesetsColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        subtitle: Text(
                          dateFormat.format(e.loggedAt),
                          style: const TextStyle(
                            color: HomesetsColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18, color: HomesetsColors.lime),
                              onPressed: () => _onEditWeightPrompt(e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: HomesetsColors.textMuted),
                              onPressed: () => _onDeleteWeight(e),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab(AppLocalizations l10n) {
    final filtered = _photoAngleFilter == null
        ? _photos
        : _photos.where((p) => p.angle == _photoAngleFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: KineticButton(
                label: l10n.addPhoto,
                icon: Icons.add_a_photo,
                onPressed: _onAddPhotoPrompt,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: l10n.comparePhotos,
              style: IconButton.styleFrom(
                backgroundColor: _isCompareMode
                    ? HomesetsColors.lime
                    : HomesetsColors.surfaceElevated,
                foregroundColor: _isCompareMode
                    ? HomesetsColors.textOnLime
                    : HomesetsColors.textPrimary,
              ),
              onPressed: () {
                setState(() {
                  _isCompareMode = !_isCompareMode;
                  _selectedForCompare.clear();
                });
              },
              icon: const Icon(Icons.compare_arrows),
            ),
          ],
        ),
        if (_isCompareMode) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: HomesetsColors.limeGlow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: HomesetsColors.lime),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${l10n.selectTwoPhotos} (${_selectedForCompare.length}/2)',
                    style: const TextStyle(
                      color: HomesetsColors.lime,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (_selectedForCompare.length == 2)
                  ElevatedButton(
                    key: const Key('compare_now_btn'),
                    onPressed: () => setState(() => _isShowingComparison = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomesetsColors.lime,
                      foregroundColor: HomesetsColors.textOnLime,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(l10n.comparePhotos,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),

        // Angle Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.allAngles),
                selected: _photoAngleFilter == null,
                onSelected: (_) => setState(() => _photoAngleFilter = null),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: Text(l10n.frontAngle),
                selected: _photoAngleFilter == PhotoAngle.front,
                onSelected: (_) => setState(() => _photoAngleFilter = PhotoAngle.front),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: Text(l10n.sideAngle),
                selected: _photoAngleFilter == PhotoAngle.side,
                onSelected: (_) => setState(() => _photoAngleFilter = PhotoAngle.side),
              ),
              const SizedBox(width: 6),
              FilterChip(
                label: Text(l10n.backAngle),
                selected: _photoAngleFilter == PhotoAngle.back,
                onSelected: (_) => setState(() => _photoAngleFilter = PhotoAngle.back),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                l10n.noPhotos,
                style: const TextStyle(color: HomesetsColors.textMuted),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (ctx, idx) {
              final photo = filtered[idx];
              final isSelectedForCompare =
                  _selectedForCompare.any((p) => p.id == photo.id);

              return GestureDetector(
                key: Key('photo_tile_${photo.id}'),
                onTap: () {
                  if (_isCompareMode) {
                    _togglePhotoSelectionForCompare(photo);
                  } else {
                    _showPhotoDetailDialog(photo);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: HomesetsColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelectedForCompare
                          ? HomesetsColors.lime
                          : HomesetsColors.borderSubtle,
                      width: isSelectedForCompare ? 2.5 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FutureBuilder<String>(
                        future: widget.photoService.getAbsolutePath(photo.filePath),
                        builder: (ctx, snap) {
                          if (snap.connectionState != ConnectionState.done) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final path = snap.data;
                          if (path == null) {
                            return const Icon(Icons.broken_image,
                                color: HomesetsColors.textMuted);
                          }
                          final file = File(path);
                          if (!file.existsSync()) {
                            return Center(
                              child: Text(
                                photo.angle.name.toUpperCase(),
                                style: const TextStyle(
                                  color: HomesetsColors.lime,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return Image.file(file, fit: BoxFit.cover);
                        },
                      ),
                      Positioned(
                        bottom: 4,
                        right: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            photo.angle.name.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (isSelectedForCompare)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: HomesetsColors.lime,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: HomesetsColors.textOnLime,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStrengthTab(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_exerciseIds.isEmpty)
          TactileCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n.noStrengthData,
                style: const TextStyle(color: HomesetsColors.textMuted),
              ),
            ),
          )
        else ...[
          // Exercise Selector Dropdown
          TactileCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedExerciseId,
                isExpanded: true,
                dropdownColor: HomesetsColors.surfaceCard,
                icon: const Icon(Icons.arrow_drop_down, color: HomesetsColors.lime),
                items: _exerciseIds.map((id) {
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(
                      id.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: HomesetsColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onSelectExercise,
              ),
            ),
          ),
          if (_availableBands.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(l10n.bandFilterAll),
                    selected: _selectedBandFilter == null || _selectedBandFilter == 'all',
                    onSelected: (_) => _onSelectBandFilter(null),
                    selectedColor: HomesetsColors.lime,
                    labelStyle: TextStyle(
                      color: (_selectedBandFilter == null || _selectedBandFilter == 'all')
                          ? HomesetsColors.textOnLime
                          : HomesetsColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ..._availableBands.map((band) {
                    final label = band == 'none' ? l10n.bandFilterBodyweight : band.replaceAll('_', ' ');
                    final isSel = _selectedBandFilter == band;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: isSel,
                        onSelected: (_) => _onSelectBandFilter(band),
                        selectedColor: HomesetsColors.lime,
                        labelStyle: TextStyle(
                          color: isSel ? HomesetsColors.textOnLime : HomesetsColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Strength Metrics summary cards
          if (_strengthSummary != null) ...[
            if (!_strengthSummary!.isComparable)
              Container(
                key: const Key('mixed_bands_banner'),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: HomesetsColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: HomesetsColors.borderSubtle),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: HomesetsColors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mixed configurations logged. Filter by band to see exact progress.',
                        style: TextStyle(color: HomesetsColors.textSecondary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final isComparable = _strengthSummary!.isComparable;
                final baselineText = isComparable ? '${_strengthSummary!.baselineMaxReps} reps' : 'Mixed';
                final bestText = isComparable ? '${_strengthSummary!.allTimeBestMaxReps} reps' : 'Mixed';
                final recentText = isComparable ? '${_strengthSummary!.recentMaxReps} reps' : 'Mixed';

                if (constraints.maxWidth < 380) {
                  return Column(
                    children: [
                      _buildMetricRow(l10n.baselineLabel, baselineText),
                      const SizedBox(height: 6),
                      _buildMetricRow(l10n.bestLabel, bestText, isHighlight: isComparable),
                      const SizedBox(height: 6),
                      _buildMetricRow(l10n.recentLabel, recentText),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildMetricCol(l10n.baselineLabel, baselineText),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCol(l10n.bestLabel, bestText, isHighlight: isComparable),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricCol(l10n.recentLabel, recentText),
                    ),
                  ],
                );
              },
            ),
            if (_strengthSummary!.isComparable && _strengthSummary!.repsDelta != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _strengthSummary!.repsDelta! >= 0
                      ? HomesetsColors.limeGlow
                      : HomesetsColors.orangeGlow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _strengthSummary!.repsDelta! >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: _strengthSummary!.repsDelta! >= 0
                          ? HomesetsColors.lime
                          : HomesetsColors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${_strengthSummary!.repsDelta! > 0 ? '+' : ''}${l10n.repsDelta(_strengthSummary!.repsDelta!)}',
                        style: TextStyle(
                          color: _strengthSummary!.repsDelta! >= 0
                              ? HomesetsColors.lime
                              : HomesetsColors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),

          // Progression Chart
          TactileCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.strengthTitle, style: HomesetsTypography.heading3),
                const SizedBox(height: 16),
                StrengthProgressionChart(points: _strengthPoints, height: 180),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMealsTab(AppLocalizations l10n) {
    return MealChecklistCard(
      mealChecks: _todayMealChecks,
      onToggle: _onToggleMeal,
    );
  }

  Widget _buildMetricRow(String label, String value, {bool isHighlight = false}) {
    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: HomesetsTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: HomesetsTypography.heading3.copyWith(
              color: isHighlight ? HomesetsColors.lime : HomesetsColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, {bool isHighlight = false}) {
    return TactileCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: HomesetsTypography.bodySmall, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            value,
            style: HomesetsTypography.heading3.copyWith(
              color: isHighlight ? HomesetsColors.lime : HomesetsColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoThumbnailTile(ProgressPhoto photo) {
    return GestureDetector(
      onTap: () => _showPhotoDetailDialog(photo),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: HomesetsColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: HomesetsColors.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<String>(
          future: widget.photoService.getAbsolutePath(photo.filePath),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final path = snap.data;
            if (path == null) {
              return const Icon(Icons.broken_image, color: HomesetsColors.textMuted);
            }
            final file = File(path);
            if (!file.existsSync()) {
              return Center(
                child: Text(
                  photo.angle.name.toUpperCase(),
                  style: const TextStyle(
                    color: HomesetsColors.lime,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              );
            }
            return Image.file(file, fit: BoxFit.cover);
          },
        ),
      ),
    );
  }

  void _showPhotoDetailDialog(ProgressPhoto photo) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: HomesetsColors.surfaceCard,
        contentPadding: const EdgeInsets.all(12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: FutureBuilder<String>(
                future: widget.photoService.getAbsolutePath(photo.filePath),
                builder: (c, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final path = snap.data;
                  if (path == null) {
                    return const Icon(Icons.broken_image, color: HomesetsColors.textMuted);
                  }
                  final file = File(path);
                  if (!file.existsSync()) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image, color: HomesetsColors.orange, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              l10n.photoPendingCleanup,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: HomesetsColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Image.file(file, fit: BoxFit.contain);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  photo.angle.name.toUpperCase(),
                  style: const TextStyle(
                    color: HomesetsColors.lime,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateFormat.format(photo.takenAt),
                  style: const TextStyle(
                    color: HomesetsColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: HomesetsColors.orange),
            tooltip: l10n.delete,
            onPressed: () {
              Navigator.of(ctx).pop();
              _onDeletePhotoPrompt(photo);
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }
}
