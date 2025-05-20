import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;  // 오류 메시지 속성 추가
  bool _isAuthenticated = false;
  
  // 마지막 회원가입 응답 저장용 변수 추가
  Map<String, dynamic>? _lastRegistrationResponse;
  
  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;  // 오류 메시지 getter
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get lastRegistrationResponse => _lastRegistrationResponse;
  
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
  
  // 로그인 - bool 반환으로 수정
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.login(email, password);
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;  // 성공 시 true 반환
    } catch (e) {
      _setError(e.toString());
      return false;  // 실패 시 false 반환
    } finally {
      _setLoading(false);
    }
  }
  
  // 회원가입 - bool 반환으로 수정 (응답 데이터는 필드에 저장)
  Future<bool> register(Map<String, dynamic> registerData, Map<String, dynamic> agreementData) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authService.register(registerData, agreementData);
      // 응답 저장
      _lastRegistrationResponse = response;
      notifyListeners();
      return true;  // 성공 시 true 반환
    } catch (e) {
      _setError(e.toString());
      return false;  // 실패 시 false 반환
    } finally {
      _setLoading(false);
    }
  }
  
  // 구글 로그인 시작 메서드 추가
  Future<GoogleSignInAccount?> startGoogleLogin() async {
    try {
      return await _authService.signInWithGoogle();
    } catch (e) {
      _setError(e.toString());
      return null;
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
  
  // 구글 회원가입 - bool 반환으로 수정
  Future<bool> googleRegister(String token, Map<String, dynamic> agreementData, String? googleId, String? name) async {
    _setLoading(true);
    _clearError();
    
    try {
      final user = await _authService.googleRegister(token, agreementData, googleId, name);
      _user = user;
      _isAuthenticated = true;
      notifyListeners();
      return true;  // 성공 시 true 반환
    } catch (e) {
      _setError(e.toString());
      return false;  // 실패 시 false 반환
    } finally {
      _setLoading(false);
    }
  }
  
  // 계정 삭제 메서드 추가
  Future<bool> deleteAccount(String? password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final isSocialUser = _user?.isSocialUser ?? false;
      await _authService.deleteAccount(password, isSocialUser);
      
      // 로그아웃 진행
      await logout();
      return true;  // 성공 시 true 반환
    } catch (e) {
      _setError(e.toString());
      return false;  // 실패 시 false 반환
    } finally {
      _setLoading(false);
    }
  }
  
  // 이메일 중복 체크 메서드 추가
  Future<bool> checkEmailAvailability(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final isAvailable = await _authService.checkEmailAvailability(email);
      return isAvailable;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 비밀번호 변경 메서드 추가
  Future<bool> changePassword(String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.changePassword(newPassword);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // 아이디 찾기 메서드 추가
  Future<Map<String, dynamic>> findUsername(String email, String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.findUsername(email, code);
      return result;
    } catch (e) {
      _setError(e.toString());
      throw e;
    } finally {
      _setLoading(false);
    }
  }
  
  // 비밀번호 재설정 메서드 추가
  Future<String> resetPassword(String email, String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.resetPassword(email, code);
      return result;
    } catch (e) {
      _setError(e.toString());
      throw e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 인증 코드 받기 메서드 추가
  Future<String> getVerificationCode(String verificationToken) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.getVerificationCode(verificationToken);
      return result;
    } catch (e) {
      _setError(e.toString());
      throw e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 이메일 인증 메서드 추가
  Future<String> verifyEmail(String email, String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.verifyEmail(email, code);
      return result;
    } catch (e) {
      _setError(e.toString());
      throw e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 인증번호 재발송 메서드 추가
  Future<String> resendVerification(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.resendVerification(email);
      return result;
    } catch (e) {
      _setError(e.toString());
      throw e.toString();
    } finally {
      _setLoading(false);
    }
  }
  
  // 계정 찾기용 인증 코드 발송 메서드 추가
  Future<String> sendVerificationForCredential(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _authService.sendVerificationForCredential(email);
      return result;
    } catch (e) {
      _setError(e.toString());
      throw e.toString();
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
    _errorMessage = error;
    notifyListeners();
  }
  
  // 에러 초기화
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}