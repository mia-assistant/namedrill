class QuizScoreModel {
  final String id;
  final String groupId;
  final int score;
  final DateTime date;

  QuizScoreModel({
    required this.id,
    required this.groupId,
    required this.score,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'score': score,
      'date': date.toIso8601String(),
    };
  }

  factory QuizScoreModel.fromMap(Map<String, dynamic> map) {
    return QuizScoreModel(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      score: map['score'] as int,
      date: DateTime.parse(map['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizScoreModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
