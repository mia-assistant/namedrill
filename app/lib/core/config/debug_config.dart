import 'package:flutter/foundation.dart';

/// Debug flags for development and screenshots
/// These only work in debug builds — release builds always use false
class DebugConfig {
  /// Force show onboarding even if already completed
  static bool get forceOnboarding => kDebugMode && _forceOnboarding;
  static const bool _forceOnboarding = false;
  
  /// Force premium status (bypass purchase check)
  static bool get fakePremium => kDebugMode && _fakePremium;
  static const bool _fakePremium = false;
  
  /// Skip onboarding entirely (go straight to home)
  static bool get skipOnboarding => kDebugMode && _skipOnboarding;
  static const bool _skipOnboarding = false;
}
