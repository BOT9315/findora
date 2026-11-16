import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_constants.dart';
import 'core/database/app_database.dart';
import 'core/security/app_lock_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/collections/data/collections_repository.dart';
import 'features/navigation/main_navigation_screen.dart';
import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/splash/presentation/findora_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Pre-initialize database and seed default collections
  try {
    await AppDatabase.instance.database;
    await CollectionsRepository().initializeDefaultCollections();
  } catch (e) {
    debugPrint('Database initialization warning: $e');
  }

  runApp(
    const ProviderScope(
      child: FindoraApp(),
    ),
  );
}

// Keep backwards-compatible alias
typedef FindMyStuffApp = FindoraApp;

class FindoraApp extends ConsumerStatefulWidget {
  const FindoraApp({super.key});

  @override
  ConsumerState<FindoraApp> createState() => _FindoraAppState();
}

class _FindoraAppState extends ConsumerState<FindoraApp>
    with WidgetsBindingObserver {
  bool _showSplash = true;
  bool _isUnlocked = true;
  bool _checkingLock = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused) {
      _checkAppLock(onPause: true);
    }
  }

  Future<void> _checkAppLock({bool onPause = false}) async {
    final lockEnabled = await AppLockService.instance.isAppLockEnabled();
    if (!lockEnabled) {
      if (mounted) {
        setState(() {
          _isUnlocked = true;
          _checkingLock = false;
        });
      }
      return;
    }

    if (onPause) {
      if (mounted) setState(() => _isUnlocked = false);
      return;
    }

    if (mounted) {
      setState(() {
        _isUnlocked = false;
        _checkingLock = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingDone = ref.watch(onboardingCompletedProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _showSplash
          ? FindoraSplashScreen(
              onAnimationComplete: () {
                if (mounted) setState(() => _showSplash = false);
              },
            )
          : _checkingLock
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                )
              : !_isUnlocked
                  ? AuthScreen(
                      onAuthenticated: () {
                        if (mounted) setState(() => _isUnlocked = true);
                      },
                    )
                  : onboardingDone
                      ? const MainNavigationScreen()
                      : const OnboardingScreen(),
    );
  }
}
