import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../services/storage_service.dart';

class ApiService {
  final StorageService _storageService = StorageService();
  
  // HTTP GET 요청
  Future<Map<String, dynamic>> get(String endpoint, {Map<String, String>? queryParams}) async {
    final String? token = await _storageService.getToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final Uri uri = Uri.parse('${AppConfig.apiBaseUrl}$endpoint')
        .replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri, headers: headers);
      return _handleResponse(response);
    } catch (e) {
      throw Exception('통신 오류가 발생했습니다: $e');
    }
  }

  // HTTP POST 요청
  Future<Map<String, dynamic>> post(String endpoint, dynamic body) async {
    final String? token = await _storageService.getToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
        headers: headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('통신 오류가 발생했습니다: $e');
    }
  }
  
  // HTTP DELETE 요청
  Future<Map<String, dynamic>> delete(String endpoint, {dynamic body}) async {
    final String? token = await _storageService.getToken();
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.apiBaseUrl}$endpoint'),
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('통신 오류가 발생했습니다: $e');
    }
  }

  // HTTP 응답 처리
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 응답 본문이 없거나 비어있는 경우 처리
      if (response.body.isEmpty) {
        return {'message': 'Success'};
      }
      
      // JSON 파싱 시도
      try {
        return json.decode(response.body);
      } catch (e) {
        // JSON이 아닌 경우 평문 텍스트로 처리
        return {'message': response.body};
      }
    } else {
      // 에러 응답 처리
      try {
        final Map<String, dynamic> errorResponse = json.decode(response.body);
        throw Exception(errorResponse['message'] ?? '서버 오류가 발생했습니다');
      } catch (e) {
        if (e is Exception) {
          throw e;
        } else {
          throw Exception(response.body.isNotEmpty 
              ? response.body 
              : '서버 오류가 발생했습니다 (${response.statusCode})');
        }
      }
    }
  }
}