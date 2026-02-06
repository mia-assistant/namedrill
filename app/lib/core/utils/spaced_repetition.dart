import '../../data/models/learning_record_model.dart';

/// SM-2 Spaced Repetition Algorithm implementation
/// Based on the algorithm by Piotr Wozniak
class SpacedRepetition {
  /// Minimum ease factor allowed
  static const double minEaseFactor = 1.3;
  
  /// Initial ease factor for new cards
  static const double initialEaseFactor = 2.5;
  
  /// Ease factor increase on correct answer
  static const double easeIncrease = 0.1;
  
  /// Ease factor decrease on incorrect answer
  static const double easeDecrease = 0.2;

  /// Process a review and return updated learning record
  static LearningRecordModel processReview({
    required LearningRecordModel record,
    required bool gotIt,
  }) {
    final now = DateTime.now();
    int newInterval;
    double newEaseFactor = record.easeFactor;

    if (!gotIt) {
      // Forgot: reset interval to 1, decrease ease factor
      newInterval = 1;
      newEaseFactor = (record.easeFactor - easeDecrease).clamp(minEaseFactor, 5.0);
    } else {
      // Got it: increase interval based on review count
      if (record.reviewCount == 0) {
        newInterval = 1; // First review
      } else if (record.reviewCount == 1) {
        newInterval = 3; // Second review
      } else {
        // Subsequent reviews: multiply by ease factor
        newInterval = (record.interval * record.easeFactor).round();
      }
      newEaseFactor = (record.easeFactor + easeIncrease).clamp(minEaseFactor, 5.0);
    }

    // Calculate next review date
    final nextReviewDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: newInterval));

    return record.copyWith(
      interval: newInterval,
      easeFactor: newEaseFactor,
      nextReviewDate: nextReviewDate,
      reviewCount: record.reviewCount + 1,
      lastReviewedAt: now,
    );
  }

  /// Calculate retention score (0-100) based on ease factor and interval
  static int calculateRetentionScore(LearningRecordModel record) {
    if (record.reviewCount == 0) return 0;
    
    // Combine ease factor and interval into a score
    final intervalScore = (record.interval / 30.0).clamp(0.0, 1.0) * 50;
    final easeScore = ((record.easeFactor - minEaseFactor) / (5.0 - minEaseFactor)) * 50;
    
    return (intervalScore + easeScore).round();
  }

  /// Check if a card should be considered "learned" (interval >= 7 days)
  static bool isLearned(LearningRecordModel record) {
    return record.interval >= 7;
  }

  /// Get priority score for card selection (lower = higher priority)
  static int getPriority(LearningRecordModel record) {
    if (record.isNew) return 2; // New cards have medium priority
    if (record.isDue) return 1; // Due cards have highest priority
    
    // Not due yet, lower priority based on days until due
    final daysUntilDue = record.nextReviewDate.difference(DateTime.now()).inDays;
    return 3 + daysUntilDue;
  }

  /// Sort cards by priority for a learn session
  static List<LearningRecordModel> sortByPriority(List<LearningRecordModel> cards) {
    final sorted = List<LearningRecordModel>.from(cards);
    sorted.sort((a, b) => getPriority(a).compareTo(getPriority(b)));
    return sorted;
  }
}
