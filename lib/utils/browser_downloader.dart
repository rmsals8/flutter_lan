import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';

class BrowserDownloader {
  // API 서버 URL
  static const String baseUrl = 'https://port-0-java-springboot-lan-m8dt2pjh3adde56e.sel4.cloudtype.app';

  // PDF 파일 브라우저로 열기
  static Future<void> openPdfInBrowser(BuildContext context, int quizId) async {
    try {
      // 토큰 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 로그인해주세요.')),
        );
        return;
      }
      
      // URL 직접 생성 (토큰 포함)
      final url = Uri.parse('$baseUrl/api/quizzes/$quizId/pdf?token=$token');
      
      debugPrint('PDF URL: $url');
      
      // 브라우저에서 URL 열기
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF를 브라우저에서 열었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF를 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('PDF 열기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // 일반 파일 브라우저로 열기
  static Future<void> openFileInBrowser(BuildContext context, int fileId) async {
    try {
      // 토큰 가져오기
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인이 필요합니다. 다시 로그인해주세요.')),
        );
        return;
      }
      
      // URL 직접 생성 (토큰 포함)
      final url = Uri.parse('$baseUrl/api/files/download/$fileId?token=$token');
      
      debugPrint('파일 URL: $url');
      
      // 브라우저에서 URL 열기
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일을 브라우저에서 열었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('파일을 열 수 없습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('파일 열기 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 토큰 추출 (Bearer 제거)
  static String _extractToken(String fullToken) {
    if (fullToken.startsWith('Bearer ')) {
      return fullToken.substring(7);
    }
    return fullToken;
  }
}