import 'package:flutter/material.dart';
import '../models/user_file.dart';
import '../services/file_service.dart';

class FileProvider extends ChangeNotifier {
  final FileService _fileService = FileService();
  
  // 상태 변수들
  List<UserFile> _allFiles = [];
  List<UserFile> _conversationFiles = [];
  List<UserFile> _audioFiles = [];
  bool _isLoading = false;
  String? _error;
  
  // 게터
  List<UserFile> get allFiles => _allFiles;
  List<UserFile> get conversationFiles => _conversationFiles;
  List<UserFile> get audioFiles => _audioFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 모든 파일 가져오기
  Future<void> fetchAllFiles() async {
    try {
      _setLoading(true);
      _clearError();
      
      final files = await _fileService.getUserFiles();
      _allFiles = files;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 대화 PDF 파일 가져오기
  Future<void> fetchConversationFiles() async {
    try {
      _setLoading(true);
      _clearError();
      
      final files = await _fileService.getUserFiles(fileType: 'CONVERSATION_PDF');
      _conversationFiles = files;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 오디오 파일 가져오기
  Future<void> fetchAudioFiles() async {
    try {
      _setLoading(true);
      _clearError();
      
      // MP3와 SCRIPT_AUDIO 타입의 파일을 모두 가져와야 함
      final mp3Files = await _fileService.getUserFiles(fileType: 'MP3');
      final scriptAudioFiles = await _fileService.getUserFiles(fileType: 'SCRIPT_AUDIO');
      
      // 두 타입의 파일 병합
      _audioFiles = [...mp3Files, ...scriptAudioFiles];
      
      // 날짜순 정렬 (최신순)
      _audioFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // 파일 삭제
  Future<bool> deleteFile(int fileId) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _fileService.deleteFile(fileId);
      
      // 삭제 후 목록 갱신
      await fetchAllFiles();
      await fetchConversationFiles();
      await fetchAudioFiles();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
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
    _error = error;
    notifyListeners();
  }
  
  // 에러 초기화
  void _clearError() {
    _error = null;
    notifyListeners();
  }
}