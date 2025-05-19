import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // 보안 스토리지 키
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_info';
  
  // 일반 스토리지 키
  static const String _themeKey = 'app_theme';
  static const String _languageKey = 'app_language';
  
  // 토큰 저장
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  // 토큰 가져오기
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  // 토큰 삭제
  Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  // 사용자 정보 저장
  Future<void> saveUserInfo(String userInfo) async {
    await _secureStorage.write(key: _userKey, value: userInfo);
  }
  
  // 사용자 정보 가져오기
  Future<String?> getUserInfo() async {
    return await _secureStorage.read(key: _userKey);
  }
  
  // 사용자 정보 삭제
  Future<void> deleteUserInfo() async {
    await _secureStorage.delete(key: _userKey);
  }
  
  // 모든 보안 저장소 데이터 삭제
  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
  
  // 테마 설정 저장
  Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }
  
  // 테마 설정 가져오기
  Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }
  
  // 언어 설정 저장
  Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }
  
  // 언어 설정 가져오기
  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }
}