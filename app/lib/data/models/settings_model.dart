enum DarkModeOption { system, light, dark }

class SettingsModel {
  final bool notificationsEnabled;
  final int notificationHour; // 0-23
  final int notificationMinute; // 0-59
  final DarkModeOption darkMode;
  final bool isPremium;
  final DateTime? premiumPurchaseDate;
  final int sessionCardCount; // How many cards per learn session

  SettingsModel({
    this.notificationsEnabled = false,
    this.notificationHour = 8,
    this.notificationMinute = 0,
    this.darkMode = DarkModeOption.system,
    this.isPremium = false,
    this.premiumPurchaseDate,
    this.sessionCardCount = 15,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled ? 1 : 0,
      'notificationHour': notificationHour,
      'notificationMinute': notificationMinute,
      'darkMode': darkMode.index,
      'isPremium': isPremium ? 1 : 0,
      'premiumPurchaseDate': premiumPurchaseDate?.toIso8601String(),
      'sessionCardCount': sessionCardCount,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      notificationsEnabled: (map['notificationsEnabled'] as int? ?? 0) == 1,
      notificationHour: map['notificationHour'] as int? ?? 8,
      notificationMinute: map['notificationMinute'] as int? ?? 0,
      darkMode: DarkModeOption.values[map['darkMode'] as int? ?? 0],
      isPremium: (map['isPremium'] as int? ?? 0) == 1,
      premiumPurchaseDate: map['premiumPurchaseDate'] != null
          ? DateTime.parse(map['premiumPurchaseDate'] as String)
          : null,
      sessionCardCount: map['sessionCardCount'] as int? ?? 15,
    );
  }

  SettingsModel copyWith({
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
    DarkModeOption? darkMode,
    bool? isPremium,
    DateTime? premiumPurchaseDate,
    int? sessionCardCount,
  }) {
    return SettingsModel(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      darkMode: darkMode ?? this.darkMode,
      isPremium: isPremium ?? this.isPremium,
      premiumPurchaseDate: premiumPurchaseDate ?? this.premiumPurchaseDate,
      sessionCardCount: sessionCardCount ?? this.sessionCardCount,
    );
  }
}
