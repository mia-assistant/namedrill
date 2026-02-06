import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'data/models/settings_model.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Check if onboarding is complete
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool(AppConstants.prefOnboardingComplete) ?? false;

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
      default:
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
