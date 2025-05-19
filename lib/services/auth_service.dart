import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/auth_response.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  
  // 일반 로그인
  Future<AuthResponse> login(String email, String password) async {
    final response = await _apiService.post(AppConfig.apiLogin, {
      'email': email,
      'password': password,
    });
    
    final authResponse = AuthResponse.fromJson(response);
    await _storageService.saveToken(authResponse.token);
    
    return authResponse;
  }
  
  // 구글 로그인 체크
  Future<GoogleCheckResponse> googleLoginCheck(String token) async {
    final response = await _apiService.post(AppConfig.apiGoogleLoginCheck, {
      'token': token,
    });
    
    final checkResponse = GoogleCheckResponse.fromJson(response);
    
    // 이미 가입된 사용자면 토큰 저장
    if (checkResponse.isRegistered && checkResponse.accessToken != null) {
      await _storageService.saveToken(checkResponse.accessToken!);
    }
    
    return checkResponse;
  }
  
  // 구글 로그인 (로그인 시도)
  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      throw Exception('구글 로그인 중 오류가 발생했습니다: $e');
    }
  }
  
  // 구글 인증 후 토큰 가져오기
  Future<String> getGoogleAuthToken() async {
    final googleAccount = await _googleSignIn.signIn();
    if (googleAccount == null) {
      throw Exception('구글 로그인이 취소되었습니다.');
    }
    
    final googleAuth = await googleAccount.authentication;
    return googleAuth.accessToken ?? '';
  }
  
  // 구글 계정 정보로 회원가입
  Future<AuthResponse> googleRegister(String token, Map<String, dynamic> agreementData, String? googleId, String? name) async {
    final response = await _apiService.post(AppConfig.apiGoogleRegister, {
      'token': token,
      'agreement': agreementData,
      'googleId': googleId,
      'name': name,
    });
    
    final authResponse = AuthResponse.fromJson(response);
    await _storageService.saveToken(authResponse.token);
    
    return authResponse;
  }
  
  // 회원가입 (약관 동의 포함)
  Future<Map<String, dynamic>> register(Map<String, dynamic> registerData, Map<String, dynamic> agreementData) async {
    final response = await _apiService.post(AppConfig.apiRegister, {
      'registerRequest': registerData,
      'agreement': agreementData,
    });
    
    return response;
  }
  
  // 이메일 중복 확인
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await _apiService.get(
        AppConfig.apiCheckEmail,
        queryParams: {'email': email},
      );
      
      // 성공 응답은 "사용 가능한 이메일입니다" 메시지
      return true;
    } catch (e) {
      // 에러 응답은 "이미 사용 중인 이메일입니다" 등의 메시지
      return false;
    }
  }
  
  // 사용자 정보 조회
  Future<User> getUserInfo() async {
    final response = await _apiService.get(AppConfig.apiUserInfo);
    final user = User.fromJson(response);
    
    // 사용자 정보 로컬 저장
    await _storageService.saveUserInfo(json.encode(user.toJson()));
    
    return user;
  }
  
  // 로그아웃
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _storageService.deleteToken();
    await _storageService.deleteUserInfo();
  }
  
  // 로그인 상태 확인
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    return token != null && token.isNotEmpty;
  }
  
  // 저장된 사용자 정보 가져오기
  Future<User?> getStoredUserInfo() async {
    final userJson = await _storageService.getUserInfo();
    if (userJson != null && userJson.isNotEmpty) {
      try {
        return User.fromJson(json.decode(userJson));
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  // 이메일 인증 코드 발송 요청
  Future<String> getVerificationCode(String verificationToken) async {
    final response = await _apiService.get(
      AppConfig.apiGetVerificationCode,
      queryParams: {'verificationToken': verificationToken},
    );
    
    return response['message'] ?? '인증번호가 발송되었습니다.';
  }
  
  // 이메일 인증
  Future<String> verifyEmail(String email, String code) async {
    final response = await _apiService.post(AppConfig.apiVerifyEmail, {
      'email': email,
      'code': code,
    });
    
    return response['message'] ?? '이메일 인증이 완료되었습니다.';
  }
  
  // 인증번호 재발송
  Future<String> resendVerification(String email) async {
    final response = await _apiService.post(AppConfig.apiResendVerification, {
      'email': email,
    });
    
    return response['message'] ?? '인증번호가 재발송되었습니다.';
  }
  
  // 계정 찾기용 인증 코드 발송
  Future<String> sendVerificationForCredential(String email) async {
    final response = await _apiService.post(AppConfig.apiSendVerificationForCredential, {
      'email': email,
    });
    
    return response['message'] ?? '인증번호가 발송되었습니다.';
  }
  
  // 아이디 찾기
  Future<Map<String, dynamic>> findUsername(String email, String code) async {
    final response = await _apiService.post(AppConfig.apiFindUsername, {
      'email': email,
      'code': code,
    });
    
    return response;
  }
  
  // 비밀번호 재설정
  Future<String> resetPassword(String email, String code) async {
    final response = await _apiService.post(AppConfig.apiResetPassword, {
      'email': email,
      'code': code,
    });
    
    return response['message'] ?? '비밀번호가 재설정되었습니다.';
  }
  
  // 비밀번호 변경
  Future<String> changePassword(String newPassword) async {
    final response = await _apiService.post(AppConfig.apiChangePassword, {
      'newPassword': newPassword,
    });
    
    return response['message'] ?? '비밀번호가 변경되었습니다.';
  }
  
  // 비밀번호 검증
  Future<bool> verifyPassword(String password) async {
    try {
      await _apiService.post(AppConfig.apiVerifyPassword, {
        'password': password,
      });
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // 계정 삭제
  Future<String> deleteAccount(String? password, bool isSocialUser) async {
    final Map<String, dynamic> body = isSocialUser 
        ? {'isSocialLogin': true}
        : {'password': password};
    
    final response = await _apiService.delete(AppConfig.apiDeleteAccount, body: body);
    
    // 로그인 정보 삭제
    await logout();
    
    return response['message'] ?? '계정이 삭제되었습니다.';
  }
}