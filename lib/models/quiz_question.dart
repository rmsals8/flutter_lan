class QuizQuestion {
  final int id;
  final String questionText;
  final String questionType; // "MULTIPLE_CHOICE" 또는 "SHORT_ANSWER"
  final List<String>? options; // 객관식 선택지 (객관식인 경우만)
  final String correctAnswer;
  final int orderIndex;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.options,
    required this.correctAnswer,
    required this.orderIndex,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      questionText: json['questionText'],
      questionType: json['questionType'],
      options: json['options'] != null 
          ? List<String>.from(json['options']) 
          : null,
      correctAnswer: json['correctAnswer'],
      orderIndex: json['orderIndex'],
    );
  }

  bool get isMultipleChoice => questionType == 'MULTIPLE_CHOICE';
}

class AnswerSubmit {
  final int questionId;
  final String userAnswer;

  AnswerSubmit({
    required this.questionId,
    required this.userAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
    };
  }
}

class AnswerResult {
  final int questionId;
  final String userAnswer;
  final bool isCorrect;

  AnswerResult({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      questionId: json['questionId'],
      userAnswer: json['userAnswer'] ?? '',
      isCorrect: json['isCorrect'] ?? false,
    );
  }
}