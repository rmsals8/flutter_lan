import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_button.dart';
import '../widgets/common_text_field.dart';
import '../widgets/common_card.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmTextController = TextEditingController();
  
  String _errorMessage = '';
  bool _isLoading = false;
  User? _user;
  bool _loadingUserData = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // 사용자 정보 가져오기
  Future<void> _fetchUserData() async {
    setState(() {
      _loadingUserData = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserInfo();
      
      setState(() {
        _user = authProvider.user;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '사용자 정보를 불러올 수 없습니다.';
      });
    } finally {
      setState(() {
        _loadingUserData = false;
      });
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmTextController.dispose();
    super.dispose();
  }

  // 계정 삭제 처리
  Future<void> _handleDeleteAccount() async {
    // 확인 텍스트 검증
    if (_confirmTextController.text != '계정삭제확인') {
      setState(() {
        _errorMessage = '확인 텍스트가 올바르지 않습니다.';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isSocialUser = _user?.isSocialUser ?? false;
      
      // 일반 계정이면서 비밀번호가 비어있는 경우 체크
      if (!isSocialUser && _passwordController.text.isEmpty) {
        setState(() {
          _errorMessage = '비밀번호를 입력해주세요.';
          _isLoading = false;
        });
        return;
      }
      
      final success = await authProvider.deleteAccount(
        isSocialUser ? null : _passwordController.text,
      );
      
      if (success && mounted) {
        // 홈 화면으로 이동
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        
        // 삭제 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('계정이 성공적으로 삭제되었습니다.'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 데이터 로딩 중 표시
    if (_loadingUserData) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('계정 삭제'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 소셜 로그인 여부 확인
    final isSocialUser = _user?.isSocialUser ?? false;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('계정 삭제'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: CardContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 뒤로가기 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_back,
                            color: AppTheme.textSecondaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '프로필로 돌아가기',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // 제목
                Center(
                  child: Text(
                    '계정 삭제',
                    style: AppTheme.titleLarge.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 경고 메시지
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.amber.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '경고: 이 작업은 되돌릴 수 없습니다',
                              style: AppTheme.bodyLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '계정을 삭제하면 다음과 같은 데이터가 영구적으로 제거됩니다:',
                              style: AppTheme.bodyMedium.copyWith(
                                color: Colors.amber.shade900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildWarningItem('모든 개인 정보'),
                                  _buildWarningItem('학습 기록 및 진행 상황'),
                                  _buildWarningItem('구독 정보'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // 비밀번호 입력 필드 (소셜 로그인이 아닌 경우만)
                if (!isSocialUser) ...[
                  CommonTextField(
                    controller: _passwordController,
                    hintText: '현재 비밀번호',
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outline),
                    labelText: '현재 비밀번호',
                  ),
                  const SizedBox(height: 16),
                ],
                
                // 계정 삭제 확인 텍스트 입력
                Text(
                  '계정을 삭제하려면 아래에 "계정삭제확인"을 입력하세요',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                CommonTextField(
                  controller: _confirmTextController,
                  hintText: '계정삭제확인',
                ),
                
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ErrorMessageBox(message: _errorMessage),
                ],
                
                const SizedBox(height: 24),
                
                // 버튼 그룹
                Row(
                  children: [
                    Expanded(
                      child: CommonButton(
                        text: '취소',
                        onPressed: () => Navigator.pop(context),
                        isOutlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonButton(
                        text: '계정 삭제',
                        onPressed: _handleDeleteAccount,
                        isLoading: _isLoading,
                        isDisabled: _confirmTextController.text != '계정삭제확인' || 
                                  (!isSocialUser && _passwordController.text.isEmpty),
                        backgroundColor: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // 경고 항목 위젯
  Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: AppTheme.bodyMedium.copyWith(
              color: Colors.amber.shade900,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}