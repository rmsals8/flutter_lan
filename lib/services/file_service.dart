import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_file.dart';
import 'api_service.dart';

class FileService {
  final ApiService _apiService = ApiService();
  
  // 토큰 가져오기
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  // 사용자 파일 목록 가져오기
  Future<List<UserFile>> getUserFiles({String? fileType}) async {
    try {
      final queryParams = fileType != null ? {'fileType': fileType} : null;
      final response = await _apiService.get('/api/files', queryParams: queryParams);
      List<dynamic> filesJson = response;
      return filesJson.map((json) => UserFile.fromJson(json)).toList();
    } catch (e) {
      debugPrint('파일 목록 가져오기 오류: $e');
      rethrow;
    }
  }
  
  // 파일 다운로드 
  Future<File> downloadFile(int fileId, String fileName) async {
    try {
      // 파일 다운로드 URL 가져오기
      final downloadUrl = _apiService.getDownloadUrl('/api/files/download/$fileId');
      debugPrint('파일 다운로드 URL: $downloadUrl'); // URL 로그

      // 인증 토큰 가져오기
      final token = await _apiService.getToken();
      debugPrint('인증 토큰: ${token?.substring(0, 20)}...'); // 토큰 일부만 로그 (보안)
      
      // 헤더에 인증 토큰 추가
      final headers = {
        'Authorization': 'Bearer $token',
      };
      debugPrint('요청 헤더: $headers');
      
      // getDownloadUrl 메서드 내부에서 이미 토큰을 URL에 추가하는지 확인
      final parsedUrl = Uri.parse(downloadUrl);
      debugPrint('파싱된 URL: ${parsedUrl.toString()}');
      debugPrint('URL에 토큰 파라미터 포함됨: ${parsedUrl.queryParameters.containsKey('token')}');
      
      // URL에 이미 토큰이 있다면 제거하고 새 URL 구성
      final Uri cleanUrl = parsedUrl.queryParameters.containsKey('token')
          ? Uri.parse('${parsedUrl.origin}${parsedUrl.path}')
          : parsedUrl;
      debugPrint('정리된 URL: ${cleanUrl.toString()}');
      
      final response = await http.get(
        cleanUrl, // 토큰이 제거된 URL 사용
        headers: headers,
      );
      
      debugPrint('응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 임시 디렉토리에 파일 저장
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('파일 저장 성공: $filePath (${response.bodyBytes.length} bytes)');
        return file;
      } else {
        final errorMsg = '파일 다운로드 실패: ${response.statusCode}, 응답: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('파일 다운로드 오류: $e');
      rethrow;
    }
  }
  
  // 파일 삭제
  Future<void> deleteFile(int fileId) async {
    try {
      await _apiService.delete('/api/files/$fileId');
    } catch (e) {
      debugPrint('파일 삭제 오류: $e');
      rethrow;
    }
  }

  // PDF 파일 다운로드 후 열기 (외부 앱 실행) 
  Future<String> downloadAndOpenPdf(int quizId, String fileName) async {
    try {
      // 파일 다운로드 URL 가져오기
      final downloadUrl = _apiService.getDownloadUrl('/api/quizzes/$quizId/pdf');
      debugPrint('PDF 다운로드 URL: $downloadUrl'); // URL 로그
      
      // 인증 토큰 가져오기
      final token = await _apiService.getToken();
      debugPrint('인증 토큰: ${token?.substring(0, 20)}...'); // 토큰 일부만 로그 (보안)
      
      // 헤더에 인증 토큰 추가
      final headers = {
        'Authorization': 'Bearer $token',
      };
      debugPrint('요청 헤더: $headers');
      
      // getDownloadUrl 메서드 내부에서 이미 토큰을 URL에 추가하는지 확인
      final parsedUrl = Uri.parse(downloadUrl);
      debugPrint('파싱된 URL: ${parsedUrl.toString()}');
      debugPrint('URL에 토큰 파라미터 포함됨: ${parsedUrl.queryParameters.containsKey('token')}');
      
      // URL에 이미 토큰이 있다면 제거하고 새 URL 구성
      final Uri cleanUrl = parsedUrl.queryParameters.containsKey('token')
          ? Uri.parse('${parsedUrl.origin}${parsedUrl.path}')
          : parsedUrl;
      debugPrint('정리된 URL: ${cleanUrl.toString()}');
      
      final response = await http.get(
        cleanUrl, // 토큰이 제거된 URL 사용
        headers: headers,
      );
      
      debugPrint('응답 상태 코드: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 임시 디렉토리에 파일 저장
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('PDF 저장 성공: $filePath (${response.bodyBytes.length} bytes)');
        return file.path;
      } else {
        final errorMsg = 'PDF 다운로드 실패: ${response.statusCode}, 응답: ${response.body.length > 100 ? response.body.substring(0, 100) + "..." : response.body}';
        debugPrint(errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      rethrow;
    }
  }
}