import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  clientId: '1061899561038-97481bo6k96inl7l57uhukdqknhtl3ce.apps.googleusercontent.com', // 웹 클라이언트 ID 추가
);
  
  // 토큰 저장
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  // 토큰 가져오기
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // 토큰 삭제
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // 사용자 정보 저장
  Future<void> saveUserInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_info', jsonEncode(user.toJson()));
  }
  
  // 사용자 정보 가져오기
  Future<User?> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_info');
    
    if (userJson != null) {
      try {
        return User.fromJson(jsonDecode(userJson));
      } catch (e) {
        debugPrint('사용자 정보 파싱 오류: $e');
        return null;
      }
    }
    
    return null;
  }
  
  // 저장된 사용자 정보 가져오기 (getUserInfo와 동일)
  Future<User?> getStoredUserInfo() async {
    return getUserInfo();
  }
  
  // 로그인
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiService.post(AppConfig.apiLogin, {
        'email': email,
        'password': password,
      });
      
      final authResponse = AuthResponse.fromJson(response);
      
      // 토큰 저장
      await saveToken(authResponse.token);
      
      // 사용자 정보 가져오기
      final user = await fetchUserInfo();
      return user;
    } catch (e) {
      debugPrint('로그인 오류: $e');
      throw Exception('로그인에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 구글 로그인 시작
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('구글 로그인 오류: $e');
      throw Exception('구글 로그인에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 구글 로그인 체크
  Future<GoogleCheckResponse> googleLoginCheck(String token) async {
    try {
      final response = await _apiService.post(AppConfig.apiGoogleLoginCheck, {
        'token': token,
      });
      
      final googleCheckResponse = GoogleCheckResponse.fromJson(response);
      
      // 이미 가입된 회원이면 토큰 저장
      if (googleCheckResponse.isRegistered && googleCheckResponse.accessToken != null) {
        await saveToken(googleCheckResponse.accessToken!);
      }
      
      return googleCheckResponse;
    } catch (e) {
      debugPrint('구글 로그인 체크 오류: $e');
      throw Exception('구글 로그인 확인에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 이메일 중복 확인
  Future<bool> checkEmailAvailability(String email) async {
    try {
      await _apiService.get(
        AppConfig.apiCheckEmail,
        queryParams: {'email': email},
      );
      return true;
    } catch (e) {
      if (e.toString().contains('이미 사용 중인 이메일입니다')) {
        return false;
      }
      throw Exception(e.toString());
    }
  }
  
  // 회원가입
  Future<Map<String, dynamic>> register(Map<String, dynamic> registerData, Map<String, dynamic> agreementData) async {
    try {
      final response = await _apiService.post(AppConfig.apiRegister, {
        'registerRequest': registerData,
        'agreement': agreementData,
      });
      
      return response;
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      throw Exception('회원가입에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 구글 계정으로 회원가입
  Future<User> googleRegister(String token, Map<String, dynamic> agreementData, String? googleId, String? name) async {
    try {
      final response = await _apiService.post(AppConfig.apiGoogleRegister, {
        'token': token,
        'agreement': agreementData,
        'googleId': googleId,
        'name': name,
      });
      
      final authResponse = AuthResponse.fromJson(response);
      
      // 토큰 저장
      await saveToken(authResponse.token);
      
      // 사용자 정보 가져오기
      final user = await fetchUserInfo();
      return user;
    } catch (e) {
      debugPrint('구글 회원가입 오류: $e');
      throw Exception('구글 계정으로 회원가입에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 인증 코드 요청 메서드 추가
  Future<String> getVerificationCode(String verificationToken) async {
    try {
      final response = await _apiService.get(
        AppConfig.apiGetVerificationCode,
        queryParams: {'verificationToken': verificationToken},
      );
      
      return response['message'] ?? '인증번호가 이메일로 발송되었습니다.';
    } catch (e) {
      debugPrint('인증 코드 요청 오류: $e');
      throw Exception('인증 코드 요청에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 이메일 인증 메서드 추가
  Future<String> verifyEmail(String email, String code) async {
    try {
      final response = await _apiService.post(AppConfig.apiVerifyEmail, {
        'email': email,
        'code': code,
      });
      
      return response['message'] ?? '이메일 인증이 완료되었습니다.';
    } catch (e) {
      debugPrint('이메일 인증 오류: $e');
      throw Exception('이메일 인증에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 인증번호 재발송 메서드 추가
  Future<String> resendVerification(String email) async {
    try {
      final response = await _apiService.post(AppConfig.apiResendVerification, {
        'email': email,
      });
      
      return response['message'] ?? '인증번호가 재발송되었습니다.';
    } catch (e) {
      debugPrint('인증번호 재발송 오류: $e');
      throw Exception('인증번호 재발송에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 계정 찾기용 인증 코드 발송 메서드 추가
  Future<String> sendVerificationForCredential(String email) async {
    try {
      final response = await _apiService.post(AppConfig.apiSendVerificationForCredential, {
        'email': email,
      });
      
      return response['message'] ?? '인증번호가 발송되었습니다.';
    } catch (e) {
      debugPrint('인증 코드 발송 오류: $e');
      throw Exception('인증 코드 발송에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 아이디 찾기 메서드 추가
  Future<Map<String, dynamic>> findUsername(String email, String code) async {
    try {
      final response = await _apiService.post(AppConfig.apiFindUsername, {
        'email': email,
        'code': code,
      });
      
      return response;
    } catch (e) {
      debugPrint('아이디 찾기 오류: $e');
      throw Exception('아이디 찾기에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 비밀번호 재설정 메서드 추가
  Future<String> resetPassword(String email, String code) async {
    try {
      final response = await _apiService.post(AppConfig.apiResetPassword, {
        'email': email,
        'code': code,
      });
      
      return response['message'] ?? '비밀번호가 재설정되었습니다.';
    } catch (e) {
      debugPrint('비밀번호 재설정 오류: $e');
      throw Exception('비밀번호 재설정에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 비밀번호 변경 메서드 추가
  Future<String> changePassword(String newPassword) async {
    try {
      final response = await _apiService.post(AppConfig.apiChangePassword, {
        'newPassword': newPassword,
      });
      
      return response['message'] ?? '비밀번호가 변경되었습니다.';
    } catch (e) {
      debugPrint('비밀번호 변경 오류: $e');
      throw Exception('비밀번호 변경에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 비밀번호 검증
  Future<bool> verifyPassword(String password) async {
    try {
      await _apiService.post(AppConfig.apiVerifyPassword, {
        'password': password,
      });
      return true;
    } catch (e) {
      debugPrint('비밀번호 검증 오류: $e');
      return false;
    }
  }
  
  // 계정 삭제
  Future<String> deleteAccount(String? password, bool isSocialUser) async {
    try {
      final Map<String, dynamic> body = isSocialUser 
          ? {'isSocialLogin': true}
          : {'password': password};
      
      final response = await _apiService.delete(AppConfig.apiDeleteAccount, body: body);
      
      // 로그인 정보 삭제
      await logout();
      
      return response['message'] ?? '계정이 삭제되었습니다.';
    } catch (e) {
      debugPrint('계정 삭제 오류: $e');
      throw Exception('계정 삭제에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 사용자 정보 가져오기
  Future<User> fetchUserInfo() async {
    try {
      final response = await _apiService.get(AppConfig.apiUserInfo);
      final user = User.fromJson(response);
      
      // 사용자 정보 로컬 저장
      await saveUserInfo(user);
      
      return user;
    } catch (e) {
      debugPrint('사용자 정보 가져오기 오류: $e');
      throw Exception('사용자 정보를 가져오는데 실패했습니다: ${e.toString()}');
    }
  }
  
  // 로그아웃
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await removeToken();
    } catch (e) {
      debugPrint('로그아웃 오류: $e');
      throw Exception('로그아웃에 실패했습니다: ${e.toString()}');
    }
  }
  
  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}