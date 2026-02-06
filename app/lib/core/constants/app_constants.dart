class AppConstants {
  // App info
  static const String appName = 'NameDrill';
  static const String appVersion = '1.0.0';
  
  // Free tier limits
  static const int maxFreeGroups = 2;
  static const int maxFreePeoplePerGroup = 25;
  
  // Learn mode defaults
  static const int defaultSessionCardCount = 15;
  static const int minSessionCardCount = 5;
  static const int maxSessionCardCount = 30;
  
  // Quiz mode
  static const int quizDurationSeconds = 60;
  static const int minPeopleForQuiz = 8; // Need at least 8 for multiple choice
  static const int quizOptionsCount = 4;
  
  // Photo settings
  static const int maxPhotoWidth = 800;
  static const int photoQuality = 80;
  
  // Shared preferences keys
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefFirstLaunch = 'first_launch';
  
  // Notification channel
  static const String notificationChannelId = 'namedrill_reminders';
  static const String notificationChannelName = 'Daily Reminders';
  static const String notificationChannelDesc = 'Daily reminders to practice names';
}
