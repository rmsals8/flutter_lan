import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAuthenticated = false;
  
  // 게터
  User? get user => _user;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  
  // 생성자
  AuthProvider() {
    _initializeAuth();
  }
  
  // 초기화
  Future<void> _initializeAuth() async {
    _setLoading(true);
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        // 로컬 저장소에서 사용자 정보 가져오기
        _user = await _authService.getStoredUserInfo();
        
        // 로컬에 사용자 정보가 없으면 서버에서 가져오기
        if (_user == null) {
          _user = await _authService.getUserInfo();
        }
        
        _isAuthenticated = true;
      }
    } catch (e) {
      _setError(e.toString());
      await _authService.logout();
      _isAuthenticated = false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 일반 로그인
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authResponse = await _authService.login(email, password);
      _user = await _authService.getUserInfo();
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 구글 로그인 시작
  Future<GoogleSignInAccount?> startGoogleLogin() async {
    _setLoading(true);
    _clearError();
    
    try {
      return await _authService.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // 구글 토큰으로 로그인 체크
  Future<GoogleCheckResponse> googleLoginCheck(String token) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authService.googleLoginCheck(token);
      
      // 이미 회원가입된 사용자면 로그인 처리
      if (response.isRegistered) {
        _user = await _authService.getUserInfo();
        _isAuthenticated = true;
      }
      
      return response;
    } catch (e) {
      _setError(e.toString());
      throw Exception(e);
    } finally {
      _setLoading(false);
    }
  }
  
  // 구글 계정으로 회원가입
  Future<bool> googleRegister(String token, Map<String, dynamic> agreementData, String? googleId, String? name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final authResponse = await _authService.googleRegister(token, agreementData, googleId, name);
      _user = await _authService.getUserInfo();
      _isAuthenticated = true;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 회원가입
  Future<Map<String, dynamic>> register(Map<String, dynamic> registerData, Map<String, dynamic> agreementData) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authService.register(registerData, agreementData);
      return response;
    } catch (e) {
      _setError(e.toString());
      throw Exception(e);
    } finally {
      _setLoading(false);
    }
  }
  
  // 이메일 중복 확인
  Future<bool> checkEmailAvailability(String email) async {
    try {
      return await _authService.checkEmailAvailability(email);
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
  
  // 로그아웃
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _user = null;
      _isAuthenticated = false;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 사용자 정보 새로고침
  Future<void> refreshUserInfo() async {
    _setLoading(true);
    try {
      _user = await _authService.getUserInfo();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 계정 삭제
  Future<bool> deleteAccount(String? password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final isSocialUser = _user?.isSocialUser ?? false;
      await _authService.deleteAccount(password, isSocialUser);
      _user = null;
      _isAuthenticated = false;
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
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
    _errorMessage = error;
    notifyListeners();
  }
  
  // 에러 초기화
  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}