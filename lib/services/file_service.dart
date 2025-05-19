import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/user_file.dart';
import 'api_service.dart';

class FileService {
  final ApiService _apiService = ApiService();
  
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
      final downloadUrl = _apiService.getDownloadUrl('/api/files/download/$fileId');
      
      // 헤더에 인증 토큰 추가 로직은 클라이언트마다 다를 수 있음
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 임시 디렉토리에 파일 저장
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
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
      final downloadUrl = _apiService.getDownloadUrl('/api/quizzes/$quizId/pdf');
      final response = await http.get(Uri.parse(downloadUrl));
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // 임시 디렉토리에 파일 저장
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      } else {
        throw Exception('PDF 다운로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('PDF 다운로드 오류: $e');
      rethrow;
    }
  }
}