import 'package:flutter/material.dart';

class Quiz {
  final int id;
  final String title;
  final int fileId;
  final String fileName;
  final int questionCount;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.fileId,
    required this.fileName,
    required this.questionCount,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      questionCount: json['questionCount'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}

class QuizDetail {
  final int id;
  final String title;
  final int fileId;
  final String fileName;
  final DateTime createdAt;
  final List<QuizQuestion> questions;

  QuizDetail({
    required this.id,
    required this.title,
    required this.fileId,
    required this.fileName,
    required this.createdAt,
    required this.questions,
  });

  factory QuizDetail.fromJson(Map<String, dynamic> json) {
    List<QuizQuestion> questionsList = [];
    if (json['questions'] != null) {
      questionsList = List<QuizQuestion>.from(
        json['questions'].map((q) => QuizQuestion.fromJson(q))
      );
    }

    return QuizDetail(
      id: json['id'],
      title: json['title'],
      fileId: json['fileId'],
      fileName: json['fileName'],
      createdAt: DateTime.parse(json['createdAt']),
      questions: questionsList,
    );
  }
}