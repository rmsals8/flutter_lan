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
      final token = await _getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      final downloadUrl = _apiService.baseUrl + '/api/files/download/$fileId';
      
      // 헤더에 인증 토큰 추가
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 임시 디렉토리에 파일 저장
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        debugPrint('파일 다운로드 실패: ${response.statusCode}, 메시지: ${response.body}');
        throw Exception('파일 다운로드 실패: ${response.statusCode}');
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
      final token = await _getToken();
      if (token == null) {
        throw Exception('인증 토큰이 없습니다. 다시 로그인해주세요.');
      }
      
      final downloadUrl = _apiService.baseUrl + '/api/quizzes/$quizId/pdf';
      
      // 헤더에 인증 토큰 추가
      final response = await http.get(
        Uri.parse(downloadUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/pdf',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 임시 디렉토리에 파일 저장
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName.pdf';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('PDF 저장 성공: $filePath');
        return file.path;
      } else {
        debugPrint('PDF 다운로드 실패: ${response.statusCode}, 메시지: ${response.body}');
        throw Exception('PDF 다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      rethrow;
    }
  }
}