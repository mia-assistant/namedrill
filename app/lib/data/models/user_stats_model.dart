class UserStatsModel {
  final int currentStreak;
  final DateTime? lastActiveDate;
  final int longestStreak;

  UserStatsModel({
    this.currentStreak = 0,
    this.lastActiveDate,
    this.longestStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'longestStreak': longestStreak,
    };
  }

  factory UserStatsModel.fromMap(Map<String, dynamic> map) {
    return UserStatsModel(
      currentStreak: map['currentStreak'] as int? ?? 0,
      lastActiveDate: map['lastActiveDate'] != null
          ? DateTime.parse(map['lastActiveDate'] as String)
          : null,
      longestStreak: map['longestStreak'] as int? ?? 0,
    );
  }

  UserStatsModel copyWith({
    int? currentStreak,
    DateTime? lastActiveDate,
    int? longestStreak,
  }) {
    return UserStatsModel(
      currentStreak: currentStreak ?? this.currentStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      longestStreak: longestStreak ?? this.longestStreak,
    );
  }

  /// Update streak based on activity
  UserStatsModel recordActivity() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (lastActiveDate == null) {
      // First ever activity
      return UserStatsModel(
        currentStreak: 1,
        lastActiveDate: today,
        longestStreak: 1,
      );
    }

    final lastActive = DateTime(
      lastActiveDate!.year,
      lastActiveDate!.month,
      lastActiveDate!.day,
    );

    final difference = today.difference(lastActive).inDays;

    if (difference == 0) {
      // Already active today
      return this;
    } else if (difference == 1) {
      // Consecutive day
      final newStreak = currentStreak + 1;
      return UserStatsModel(
        currentStreak: newStreak,
        lastActiveDate: today,
        longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
      );
    } else {
      // Streak broken
      return UserStatsModel(
        currentStreak: 1,
        lastActiveDate: today,
        longestStreak: longestStreak,
      );
    }
  }
}
