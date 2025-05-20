import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import './user_files_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _showChangePassword = false;
  bool _showCancelConfirm = false;
  String _currentPassword = '';
  bool _isProcessing = false;
  String? _error;
  
  // 비밀번호 변경 처리
  Future<void> _handleChangePassword() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    
    try {
      // 비밀번호 검증 및 변경 화면으로 이동
      // TODO: 비밀번호 검증 및 변경 화면 이동 로직 구현
      
      setState(() {
        _showChangePassword = false;
        _currentPassword = '';
      });
      
      // 비밀번호 변경 화면으로 이동
      Navigator.pushNamed(context, '/change-password');
      
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // 구독 취소 처리
  Future<void> _handleCancelSubscription() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    
    try {
      // 구독 취소 로직
      // TODO: 구독 취소 API 호출 로직 구현
      
      setState(() {
        _showCancelConfirm = false;
      });
      
      // 사용자 정보 갱신
      await Provider.of<AuthProvider>(context, listen: false).refreshUserInfo();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구독이 취소되었습니다')),
      );
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _showCancelConfirm = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('구독 취소 오류: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // 로그아웃 처리
  Future<void> _handleLogout() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false).logout();
      
      // 로그인 화면으로 이동
      Navigator.pushNamedAndRemoveUntil(
        context, 
        '/login', 
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 오류: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('내 프로필'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.user;
          
          if (user == null) {
            return const Center(
              child: Text('사용자 정보를 불러올 수 없습니다'),
            );
          }
          
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 프로필 헤더
                        Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.username,
                                  style: AppTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user.email,
                                  style: AppTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        
                        // 프로필 정보
                        _buildInfoItem(
                          Icons.stars,
                          '구독 상태',
                          user.isPremium ? '프리미엄 사용자' : '무료 사용자',
                          user.isPremium ? AppTheme.secondaryColor : null,
                        ),
                        if (user.subscriptionStatus != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            Icons.event_note,
                            '구독 상태',
                            user.subscriptionStatus!,
                          ),
                        ],
                        if (user.subscriptionEndDate != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoItem(
                            Icons.event,
                            '구독 만료일',
                            user.subscriptionEndDate!,
                          ),
                        ],
                        const SizedBox(height: 24),
                        
                        // 프로필 액션 버튼들
                        _buildActionButton(
                          Icons.key,
                          '비밀번호 변경',
                          () => setState(() {
                            _showChangePassword = !_showChangePassword;
                          }),
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          Icons.credit_card,
                          user.isPremium ? '구독 취소' : '구독하기',
                          () {
                            if (user.isPremium) {
                              setState(() {
                                _showCancelConfirm = true;
                              });
                            } else {
                              Navigator.pushNamed(context, '/subscription');
                            }
                          },
                          user.isPremium ? AppTheme.warningColor : null,
                        ),
                        const SizedBox(height: 8),
                        _buildActionButton(
                          Icons.logout,
                          '로그아웃',
                          _handleLogout,
                          AppTheme.errorColor,
                        ),
                        
                        // 구독 취소 확인 대화상자
                        if (_showCancelConfirm)
                          _buildCancelConfirmDialog(),
                        
                        // 비밀번호 변경 폼
                        if (_showChangePassword) ...[
                          const SizedBox(height: 16),
                          TextField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: '현재 비밀번호',
                              hintText: '현재 비밀번호 입력',
                            ),
                            onChanged: (value) => _currentPassword = value,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing || _currentPassword.isEmpty
                                  ? null
                                  : _handleChangePassword,
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('인증 및 변경'),
                            ),
                          ),
                        ],
                        
                        // 에러 메시지
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: AppTheme.errorColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 내 파일 섹션 - 고정 높이 컨테이너로 감싸기
                  Container(
                    height: 500, // 필요에 따라 조정
                    child: const UserFilesScreen(),
                  ),
                  const SizedBox(height: 24),
                  
                  // 회원 탈퇴 섹션
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_outlined,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '위험 구역',
                              style: TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '계정을 삭제하면 모든 데이터가 영구적으로 제거되며 복구할 수 없습니다.',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            icon: const Icon(Icons.person_remove),
                            label: const Text('계정 삭제'),
                            onPressed: () {
                              Navigator.pushNamed(context, '/delete-account');
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  // 프로필 정보 항목 위젯
  Widget _buildInfoItem(IconData icon, String label, String value, [Color? valueColor]) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  // 액션 버튼 위젯
  Widget _buildActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed, [
    Color? color,
  ]) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
  
  // 구독 취소 확인 대화상자
  Widget _buildCancelConfirmDialog() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '구독 취소 확인',
            style: TextStyle(
              color: AppTheme.errorColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '정말로 구독을 취소하시겠습니까? 취소 시 프리미엄 기능을 사용할 수 없게 됩니다.',
            style: AppTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () => setState(() {
                          _showCancelConfirm = false;
                        }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('아니오'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleCancelSubscription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('예'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}