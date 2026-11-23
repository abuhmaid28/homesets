import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'core/theme/homesets_colors.dart';
import 'core/theme/homesets_theme.dart';
import 'core/theme/homesets_typography.dart';
import 'data/repositories/workout_repository.dart';
import 'data/services/backup_archive_service.dart';
import 'data/services/backup_platform_service.dart';
import 'data/services/backup_staging_manager.dart';
import 'data/services/photo_service.dart';
import 'data/services/reminder_platform_service.dart';
import 'domain/models/domain_models.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/today/today_screen.dart';
import 'features/progress/progress_hub_screen.dart';
import 'features/workout/workout_player_screen.dart';
import 'features/summary/summary_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = WorkoutRepository();
  runApp(HomesetsApp(repository: repository));
}

class HomesetsApp extends StatefulWidget {
  final WorkoutRepository repository;
  final PhotoService? photoService;
  final BackupPlatformService? backupPlatformService;
  final BackupArchiveService? backupArchiveService;
  final BackupStagingManager? backupStagingManager;
  final ReminderPlatformService? reminderPlatformService;
  final Locale? locale;

  const HomesetsApp({
    super.key,
    required this.repository,
    this.photoService,
    this.backupPlatformService,
    this.backupArchiveService,
    this.backupStagingManager,
    this.reminderPlatformService,
    this.locale,
  });

  @override
  State<HomesetsApp> createState() => _HomesetsAppState();
}

class _HomesetsAppState extends State<HomesetsApp> {
  bool _isLoading = true;
  String? _recoveryError;
  bool _hasProfile = false;
  bool _isEditingSettings = false;
  bool _isViewingSettings = false;
  int _currentNavIndex = 0; // 0=Today, 1=Progress
  late final PhotoService _photoService = widget.photoService ?? AndroidPhotoService();
  late final BackupPlatformService _backupPlatformService =
      widget.backupPlatformService ?? const AndroidBackupPlatformService();
  late final BackupArchiveService _backupArchiveService =
      widget.backupArchiveService ?? const BackupArchiveService();
  BackupStagingManager? _backupStagingManager;
  late final ReminderPlatformService _reminderPlatformService =
      widget.reminderPlatformService ?? const AndroidReminderPlatformService();

  UserProfile? _currentProfile;
  EquipmentInventory? _currentInventory;
  ScheduledSession? _activeSession;
  bool _isResume = false;
  CompletedWorkoutSession? _completedSession;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  Future<void> _checkInitialState() async {
    // 1. Initialize BackupStagingManager FIRST (P6-FINAL-03, P6-LAST-03)
    if (widget.backupStagingManager != null) {
      _backupStagingManager = widget.backupStagingManager;
    } else {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        _backupStagingManager = BackupStagingManager(appDocsDir: docsDir);
      } catch (e) {
        // P6-LAST-03: Never silently fall back to systemTemp in production!
        // Fail closed with a user-facing error screen and block all DB/photo writes.
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _recoveryError =
              'Storage initialization failed: Unable to access app storage. Please verify storage permissions and restart.';
        });
        return;
      }
    }

    // 2. Perform blocking startup crash recovery BEFORE any normal DB reads or photo cleanup (P6-FINAL-03)
    final recovery = await _backupStagingManager!.recoverPendingJournal(
      repository: widget.repository,
    );

    if (recovery.isFailure) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _recoveryError = recovery.error ?? 'Startup recovery failed';
      });
      return;
    }

    // 3. Safe normal startup reads
    final profile = await widget.repository.getUserProfile();
    final inventory = await widget.repository.getEquipmentInventory();

    // 4. Safe orphan photo cleanup ONLY after recovery succeeds
    try {
      final photos = await widget.repository.getProgressPhotos();
      final validPaths = photos.map((p) => p.filePath).toList();
      await _photoService.cleanupOrphanPhotos(validPaths);
    } catch (_) {}

    // 5. Daily reminder startup reconciliation and restore (WP08, P6-NOTIFY-01)
    try {
      final reminderSettings = await widget.repository.getReminderSettings();
      if (reminderSettings.isEnabled) {
        final notificationsEnabled = await _reminderPlatformService.areNotificationsEnabled();
        if (notificationsEnabled) {
          await _reminderPlatformService.scheduleDailyReminder(
            hour: reminderSettings.hour,
            minute: reminderSettings.minute,
            title: 'HOMESETS',
            body: 'Ready for your workout?',
          );
        } else {
          // Reconcile if permission was revoked while app was closed:
          // Explicitly cancel the existing scheduled alarm so it does not persist in
          // AlarmManager and fire if the user later regrants permission without an app opt-in (P6-NOTIFY-01, P6-NOTIFY-04).
          bool cancelSuccess = false;
          try {
            cancelSuccess = await _reminderPlatformService.cancelDailyReminder();
          } catch (_) {
            cancelSuccess = false;
          }

          if (cancelSuccess) {
            final reconciled = reminderSettings.copyWith(
              isEnabled: false,
              updatedAt: DateTime.now(),
            );
            await widget.repository.saveReminderSettings(reconciled);
          } else {
            // P6-NOTIFY-04: Cancellation was not confirmed.
            // Do NOT overwrite SQLite with isEnabled: false!
            // Retain isEnabled: true so the application does not falsely claim the alarm is disabled.
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _hasProfile = profile != null;
      _currentProfile = profile;
      _currentInventory = inventory;
      _isLoading = false;
      _recoveryError = null;
    });
  }

  void _onOnboardingComplete() {
    setState(() {
      _hasProfile = true;
      _isEditingSettings = false;
    });
  }

  void _onStartWorkout(ScheduledSession session, bool isResume) {
    setState(() {
      _activeSession = session;
      _isResume = isResume;
      _completedSession = null;
    });
  }

  void _onFinishWorkout(CompletedWorkoutSession session) {
    setState(() {
      _activeSession = null;
      _completedSession = session;
    });
  }

  void _onBackToToday() {
    setState(() {
      _activeSession = null;
      _completedSession = null;
      _isEditingSettings = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HOMESETS',
      locale: widget.locale,
      debugShowCheckedModeBanner: false,
      theme: HomesetsTheme.darkTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''),
        Locale('en', ''),
      ],
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (_recoveryError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: HomesetsColors.orange, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Recovery Incomplete',
                    style: HomesetsTypography.heading2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _recoveryError!,
                    style: HomesetsTypography.bodyMedium.copyWith(color: HomesetsColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HomesetsColors.lime,
                      foregroundColor: HomesetsColors.textOnLime,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _recoveryError = null;
                      });
                      _checkInitialState();
                    },
                    child: const Text('Retry Recovery'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasProfile || _isEditingSettings) {
      return OnboardingScreen(
        repository: widget.repository,
        initialProfile: _currentProfile,
        initialInventory: _currentInventory,
        isEditing: _isEditingSettings,
        onCancel: _isEditingSettings ? () => setState(() => _isEditingSettings = false) : null,
        onCompleted: _onOnboardingComplete,
      );
    }

    if (_isViewingSettings && _backupStagingManager != null) {
      return SettingsScreen(
        repository: widget.repository,
        backupPlatformService: _backupPlatformService,
        backupArchiveService: _backupArchiveService,
        backupStagingManager: _backupStagingManager!,
        reminderPlatformService: _reminderPlatformService,
        onEditProfile: () async {
          final profile = await widget.repository.getUserProfile();
          final inventory = await widget.repository.getEquipmentInventory();
          setState(() {
            _currentProfile = profile;
            _currentInventory = inventory;
            _isEditingSettings = true;
            _isViewingSettings = false;
          });
        },
        onBack: () => setState(() => _isViewingSettings = false),
        onDataRestored: () async {
          await _checkInitialState();
          if (mounted) setState(() => _isViewingSettings = false);
        },
      );
    }

    if (_completedSession != null) {
      return SummaryScreen(
        session: _completedSession!,
        onBackToToday: _onBackToToday,
      );
    }

    if (_activeSession != null) {
      return WorkoutPlayerScreen(
        session: _activeSession!,
        repository: widget.repository,
        isResume: _isResume,
        onFinishSession: _onFinishWorkout,
        onQuit: _onBackToToday,
      );
    }

    return _MainNavigationShell(
      currentIndex: _currentNavIndex,
      onNavChanged: (index) => setState(() => _currentNavIndex = index),
      child: _currentNavIndex == 0
          ? TodayScreen(
              repository: widget.repository,
              onStartWorkout: _onStartWorkout,
              onOpenSettings: () {
                setState(() => _isViewingSettings = true);
              },
            )
          : ProgressHubScreen(
              repository: widget.repository,
              photoService: _photoService,
            ),
    );
  }
}

class _MainNavigationShell extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavChanged;
  final Widget child;

  const _MainNavigationShell({
    required this.currentIndex,
    required this.onNavChanged,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final todayLabel = l10n?.navToday ?? 'Today';
    final progressLabel = l10n?.navProgress ?? 'Progress';

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: HomesetsColors.borderSubtle, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: onNavChanged,
          backgroundColor: HomesetsColors.surface,
          indicatorColor: HomesetsColors.lime,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.fitness_center_outlined, color: HomesetsColors.textSecondary),
              selectedIcon: const Icon(Icons.fitness_center, color: HomesetsColors.textOnLime),
              label: todayLabel,
            ),
            NavigationDestination(
              icon: const Icon(Icons.trending_up_outlined, color: HomesetsColors.textSecondary),
              selectedIcon: const Icon(Icons.trending_up, color: HomesetsColors.textOnLime),
              label: progressLabel,
            ),
          ],
        ),
      ),
    );
  }
}
