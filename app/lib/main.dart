import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/debug_config.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/test_data_seeder.dart';
import 'data/models/person_model.dart';
import 'data/models/settings_model.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

// Test mode flag - set via --dart-define=TEST_MODE=true
const bool kTestMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

// Screenshot mode flag - seeds multiple groups for store listing screenshots
// set via --dart-define=SCREENSHOT_MODE=true
const bool kScreenshotMode = bool.fromEnvironment('SCREENSHOT_MODE', defaultValue: false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint('=== APP STARTUP ===');
  debugPrint('kTestMode: $kTestMode');
  debugPrint('kScreenshotMode: $kScreenshotMode');
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize notification service
  await NotificationService.instance.init();

  // Initialize photo path resolver for container-safe paths
  await PersonModel.initPhotoResolver();

  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  bool onboardingComplete = prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;

  // Debug overrides
  if (DebugConfig.forceOnboarding) {
    debugPrint('DEBUG: Forcing onboarding');
    onboardingComplete = false;
  }
  if (DebugConfig.skipOnboarding) {
    debugPrint('DEBUG: Skipping onboarding');
    onboardingComplete = true;
  }

  // In screenshot mode, seed multiple groups for store listing
  if (kScreenshotMode) {
    debugPrint('SCREENSHOT MODE: Seeding screenshot data...');
    await TestDataSeeder.seedScreenshotData();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    onboardingComplete = true;
    debugPrint('SCREENSHOT MODE: Screenshot data seeded successfully');
  }
  // In test mode, seed test data and skip onboarding
  else if (kTestMode) {
    debugPrint('TEST MODE: Seeding test data...');
    await TestDataSeeder.clearAllData();
    await TestDataSeeder.seedTestGroup(groupName: 'Test Group', peopleCount: 10);
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    onboardingComplete = true;
    debugPrint('TEST MODE: Test data seeded successfully');
  }

  runApp(
    ProviderScope(
      child: NameDrillApp(showOnboarding: !onboardingComplete),
    ),
  );
}

class NameDrillApp extends ConsumerWidget {
  final bool showOnboarding;

  const NameDrillApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    
    return settingsAsync.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
      data: (settings) => _buildApp(context, settings, showOnboarding),
    );
  }

  Widget _buildApp(BuildContext context, SettingsModel settings, bool showOnboarding) {
    ThemeMode themeMode;
    switch (settings.darkMode) {
      case DarkModeOption.light:
        themeMode = ThemeMode.light;
        break;
      case DarkModeOption.dark:
        themeMode = ThemeMode.dark;
        break;
      case DarkModeOption.system:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      home: showOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
