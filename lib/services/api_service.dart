import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  final String baseUrl = AppConfig.apiBaseUrl;
  
  // 토큰 가져오기
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // HTTP Headers 설정
  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // GET 요청
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint').replace(
      queryParameters: queryParams?.map((key, value) => MapEntry(key, value.toString())),
    );
    
    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET 요청 오류: $e');
      throw Exception('네트워크 오류가 발생했습니다.');
    }
  }

  // POST 요청
  Future<dynamic> post(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST 요청 오류: $e');
      throw Exception('네트워크 오류가 발생했습니다.');
    }
  }

  // PUT 요청
  Future<dynamic> put(String endpoint, dynamic body) async {
    final headers = await _getHeaders();
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT 요청 오류: $e');
      throw Exception('네트워크 오류가 발생했습니다.');
    }
  }

  // DELETE 요청
Future<dynamic> delete(String endpoint, {dynamic body}) async {
  final headers = await _getHeaders();
  final uri = Uri.parse('$baseUrl$endpoint');
  
  try {
    final response = body != null 
      ? await http.delete(
          uri, 
          headers: headers,
          body: jsonEncode(body),
        )
      : await http.delete(uri, headers: headers);
      
    return _handleResponse(response);
  } catch (e) {
    debugPrint('DELETE 요청 오류: $e');
    throw Exception('네트워크 오류가 발생했습니다.');
  }
}
  // 파일 다운로드 URL 생성
  String getDownloadUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  // 응답 처리
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 응답이 비어있는 경우 처리
      if (response.body.isEmpty) {
        return {};
      }
      
      // JSON 응답 파싱
      try {
        return jsonDecode(response.body);
      } catch (e) {
        debugPrint('JSON 파싱 오류: $e');
        return response.body;
      }
    } else {
      // 에러 응답 처리
      String message = '오류가 발생했습니다.';
      try {
        final errorData = jsonDecode(response.body);
        message = errorData['message'] ?? '서버 오류가 발생했습니다.';
      } catch (e) {
        message = response.body.isNotEmpty 
            ? response.body 
            : '오류 코드: ${response.statusCode}';
      }
      
      throw Exception(message);
    }
  }
}