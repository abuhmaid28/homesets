import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/homesets_colors.dart';
import 'core/theme/homesets_theme.dart';
import 'data/repositories/workout_repository.dart';
import 'data/services/photo_service.dart';
import 'domain/models/domain_models.dart';
import 'features/onboarding/onboarding_screen.dart';
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
  final Locale? locale;

  const HomesetsApp({
    super.key,
    required this.repository,
    this.photoService,
    this.locale,
  });

  @override
  State<HomesetsApp> createState() => _HomesetsAppState();
}

class _HomesetsAppState extends State<HomesetsApp> {
  bool _isLoading = true;
  bool _hasProfile = false;
  bool _isEditingSettings = false;
  int _currentNavIndex = 0; // 0=Today, 1=Progress
  late final PhotoService _photoService = widget.photoService ?? AndroidPhotoService();
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
    final profile = await widget.repository.getUserProfile();
    final inventory = await widget.repository.getEquipmentInventory();

    // P5-R02: Startup orphan photo cleanup once DB is verified healthy
    try {
      final photos = await widget.repository.getProgressPhotos();
      final validPaths = photos.map((p) => p.filePath).toList();
      await _photoService.cleanupOrphanPhotos(validPaths);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _hasProfile = profile != null;
      _currentProfile = profile;
      _currentInventory = inventory;
      _isLoading = false;
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
              onOpenSettings: () async {
                final profile = await widget.repository.getUserProfile();
                final inventory = await widget.repository.getEquipmentInventory();
                setState(() {
                  _currentProfile = profile;
                  _currentInventory = inventory;
                  _isEditingSettings = true;
                });
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
