import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../models/quiz_question.dart';
import '../models/quiz_attempt.dart';
import '../models/quiz_answer.dart';
import 'api_service.dart';

class QuizService {
  final ApiService _apiService = ApiService();
  
  // 퀴즈 목록 가져오기
  Future<List<Quiz>> getUserQuizzes() async {
    try {
      final response = await _apiService.get('/api/quizzes');
      List<dynamic> quizzesJson = response;
      return quizzesJson.map((json) => Quiz.fromJson(json)).toList();
    } catch (e) {
      debugPrint('퀴즈 목록 가져오기 오류: $e');
      rethrow;
    }
  }
  
  // 퀴즈 상세 정보 가져오기
  Future<QuizDetail> getQuizDetails(int quizId) async {
    try {
      final response = await _apiService.get('/api/quizzes/$quizId');
      return QuizDetail.fromJson(response);
    } catch (e) {
      debugPrint('퀴즈 상세 정보 가져오기 오류: $e');
      rethrow;
    }
  }
  
  // PDF 파일로부터 퀴즈 생성하기
  Future<Quiz> generateQuizFromPdf(
    int fileId, 
    String title, 
    int numMultipleChoice, 
    int numShortAnswer
  ) async {
    try {
      final response = await _apiService.post('/api/quizzes/generate', {
        'fileId': fileId,
        'title': title,
        'numMultipleChoice': numMultipleChoice,
        'numShortAnswer': numShortAnswer
      });
      
      return Quiz.fromJson(response);
    } catch (e) {
      debugPrint('퀴즈 생성 오류: $e');
      rethrow;
    }
  }
  
  // 퀴즈 응시 시작
  Future<QuizAttempt> startQuizAttempt(int quizId) async {
    try {
      final response = await _apiService.post('/api/quizzes/$quizId/start', {});
      return QuizAttempt.fromJson(response);
    } catch (e) {
      debugPrint('퀴즈 응시 시작 오류: $e');
      rethrow;
    }
  }
  
  // 퀴즈 응시 완료
  Future<QuizAttempt> completeQuizAttempt(int attemptId) async {
    try {
      final response = await _apiService.post('/api/quizzes/attempts/$attemptId/complete', {});
      return QuizAttempt.fromJson(response);
    } catch (e) {
      debugPrint('퀴즈 응시 완료 오류: $e');
      rethrow;
    }
  }
  
  // 퀴즈 응시 결과 가져오기
  Future<QuizAttemptResult> getQuizAttemptResult(int attemptId) async {
    try {
      final response = await _apiService.get('/api/quizzes/attempts/$attemptId');
      return QuizAttemptResult.fromJson(response);
    } catch (e) {
      debugPrint('퀴즈 응시 결과 가져오기 오류: $e');
      rethrow;
    }
  }
  
  // 퀴즈 답변 일괄 제출
  Future<List<AnswerResult>> submitAllAnswers(
    int attemptId, 
    List<AnswerSubmit> answers
  ) async {
    try {
      final answersList = answers.map((answer) => {
        'questionId': answer.questionId,
        'userAnswer': answer.userAnswer,
      }).toList();
      
      final response = await _apiService.post(
        '/api/quizzes/attempts/$attemptId/submit-all', 
        {'answers': answersList}
      );
      
      List<dynamic> resultsJson = response;
      return resultsJson.map((json) => AnswerResult.fromJson(json)).toList();
    } catch (e) {
      debugPrint('퀴즈 답변 일괄 제출 오류: $e');
      rethrow;
    }
  }
  
  // 퀴즈 응시 답변 목록 가져오기
  Future<List<AnswerResult>> getQuizAttemptAnswers(int attemptId) async {
    try {
      final response = await _apiService.get('/api/quizzes/attempts/$attemptId/answers');
      List<dynamic> answersJson = response;
      return answersJson.map((json) => AnswerResult.fromJson(json)).toList();
    } catch (e) {
      debugPrint('퀴즈 응시 답변 목록 가져오기 오류: $e');
      
      // 로컬 스토리지 사용 시 대체 로직도 추가 가능
      return [];
    }
  }
  
  // 퀴즈 PDF 다운로드 URL 가져오기
  String getQuizPdfDownloadUrl(int quizId) {
    return '/api/quizzes/$quizId/pdf';
  }
}