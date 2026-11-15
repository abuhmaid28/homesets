import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/homesets_theme.dart';
import 'data/repositories/workout_repository.dart';
import 'domain/models/domain_models.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/today/today_screen.dart';
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
  final Locale? locale;

  const HomesetsApp({super.key, required this.repository, this.locale});

  @override
  State<HomesetsApp> createState() => _HomesetsAppState();
}

class _HomesetsAppState extends State<HomesetsApp> {
  bool _isLoading = true;
  bool _hasProfile = false;
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
    if (!mounted) return;
    setState(() {
      _hasProfile = profile != null;
      _isLoading = false;
    });
  }

  void _onOnboardingComplete() {
    setState(() {
      _hasProfile = true;
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

    if (!_hasProfile) {
      return OnboardingScreen(
        repository: widget.repository,
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

    return TodayScreen(
      repository: widget.repository,
      onStartWorkout: _onStartWorkout,
      onOpenSettings: () {
        // Toggle back to onboarding to adjust equipment/joints if desired
        setState(() => _hasProfile = false);
      },
    );
  }
}
