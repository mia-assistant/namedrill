class LearningRecordModel {
  final String id;
  final String personId;
  final int interval; // days until next review
  final double easeFactor; // SM-2 ease factor
  final DateTime nextReviewDate;
  final int reviewCount;
  final DateTime? lastReviewedAt;

  LearningRecordModel({
    required this.id,
    required this.personId,
    this.interval = 0,
    this.easeFactor = 2.5, // Default SM-2 starting ease factor
    required this.nextReviewDate,
    this.reviewCount = 0,
    this.lastReviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'personId': personId,
      'interval': interval,
      'easeFactor': easeFactor,
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'reviewCount': reviewCount,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  factory LearningRecordModel.fromMap(Map<String, dynamic> map) {
    return LearningRecordModel(
      id: map['id'] as String,
      personId: map['personId'] as String,
      interval: map['interval'] as int,
      easeFactor: (map['easeFactor'] as num).toDouble(),
      nextReviewDate: DateTime.parse(map['nextReviewDate'] as String),
      reviewCount: map['reviewCount'] as int,
      lastReviewedAt: map['lastReviewedAt'] != null
          ? DateTime.parse(map['lastReviewedAt'] as String)
          : null,
    );
  }

  LearningRecordModel copyWith({
    String? id,
    String? personId,
    int? interval,
    double? easeFactor,
    DateTime? nextReviewDate,
    int? reviewCount,
    DateTime? lastReviewedAt,
  }) {
    return LearningRecordModel(
      id: id ?? this.id,
      personId: personId ?? this.personId,
      interval: interval ?? this.interval,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      reviewCount: reviewCount ?? this.reviewCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  /// Check if this card is due for review
  bool get isDue => DateTime.now().isAfter(nextReviewDate) || 
                    DateTime.now().day == nextReviewDate.day;

  /// Check if this is a new card (never reviewed)
  bool get isNew => reviewCount == 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LearningRecordModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
