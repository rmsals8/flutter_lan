import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';

class QuizProvider extends ChangeNotifier {
  final QuizService _quizService = QuizService();
  
  // 상태 변수들
  List<Quiz> _quizzes = [];
  QuizDetail? _currentQuizDetail;
  bool _isLoading = false;
  String? _error;
  
  // 게터
  List<Quiz> get quizzes => _quizzes;
  QuizDetail? get currentQuizDetail => _currentQuizDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 퀴즈 목록 가져오기
  Future<void> fetchQuizzes() async {
    try {
      _setLoading(true);
      _clearError();
      
      final quizzes = await _quizService.getUserQuizzes();
      _quizzes = quizzes;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 퀴즈 상세 정보 가져오기
  Future<void> fetchQuizDetail(int quizId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final quizDetail = await _quizService.getQuizDetails(quizId);
      _currentQuizDetail = quizDetail;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 퀴즈 생성하기
  Future<Quiz?> generateQuiz(int fileId, String title, int numMultipleChoice, int numShortAnswer) async {
    try {
      _setLoading(true);
      _clearError();
      
      final quiz = await _quizService.generateQuizFromPdf(
        fileId, 
        title, 
        numMultipleChoice, 
        numShortAnswer
      );
      
      // 퀴즈 목록 새로고침
      await fetchQuizzes();
      
      return quiz;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // 에러 설정
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  // 에러 초기화
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}