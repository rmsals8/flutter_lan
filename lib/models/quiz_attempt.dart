class QuizAttempt {
  final int id;
  final int quizId;
  final String quizTitle;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? score;
  final int totalQuestions;
  final int answeredQuestions;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.startedAt,
    this.completedAt,
    this.score,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quizId'],
      quizTitle: json['quizTitle'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      score: json['score'],
      totalQuestions: json['totalQuestions'],
      answeredQuestions: json['answeredQuestions'],
    );
  }

  bool get isCompleted => completedAt != null;
}

class QuizAttemptResult {
  final int id;
  final int quizId;
  final String quizTitle;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int score;
  final int totalQuestions;
  final int answeredQuestions;

  QuizAttemptResult({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.startedAt,
    this.completedAt,
    required this.score,
    required this.totalQuestions,
    required this.answeredQuestions,
  });

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResult(
      id: json['id'],
      quizId: json['quizId'],
      quizTitle: json['quizTitle'],
      startedAt: DateTime.parse(json['startedAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      score: json['score'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      answeredQuestions: json['answeredQuestions'] ?? 0,
    );
  }
}