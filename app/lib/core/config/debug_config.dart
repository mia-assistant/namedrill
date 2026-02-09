import 'package:flutter/foundation.dart';

/// Debug flags for development and screenshots
/// These only work in debug builds — release builds always use false
class DebugConfig {
  /// Force show onboarding even if already completed
  static const bool forceOnboarding = true;
  
  /// Force premium status (bypass purchase check)
  static const bool fakePremium = true;
  
  /// Skip onboarding entirely (go straight to home)
  static bool get skipOnboarding => kDebugMode && _skipOnboarding;
  static const bool _skipOnboarding = false;
}
