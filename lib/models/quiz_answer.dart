class QuizAnswer {
  final int id;
  final int questionId;
  final String userAnswer;
  final bool isCorrect;

  QuizAnswer({
    required this.id,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'] ?? 0,
      questionId: json['questionId'],
      userAnswer: json['userAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}