import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  
  // 초기화 메서드
  Future<void> init() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (isLoggedIn) {
        _user = await _authService.getStoredUserInfo();
        _isAuthenticated = _user != null;
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 로그인
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.login(email, password);
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 회원가입
  Future<void> register(Map<String, dynamic> registerData, Map<String, dynamic> agreementData) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.register(registerData, agreementData);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 구글 로그인 체크
  Future<GoogleCheckResponse> googleLoginCheck(String token) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authService.googleLoginCheck(token);
      
      if (response.isRegistered) {
        await refreshUserInfo();
      }
      
      return response;
    } catch (e) {
      _setError(e.toString());
      throw e;
    } finally {
      _setLoading(false);
    }
  }
  
  // 구글 회원가입
  Future<void> googleRegister(String token, Map<String, dynamic> agreementData, String? googleId, String? name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.googleRegister(token, agreementData, googleId, name);
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 사용자 정보 새로고침
  Future<void> refreshUserInfo() async {
    try {
      final user = await _authService.fetchUserInfo();
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }
  
  // 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
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