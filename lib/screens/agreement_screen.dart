import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/common_button.dart';
import '../widgets/common_card.dart';

class AgreementScreen extends StatefulWidget {
  const AgreementScreen({Key? key}) : super(key: key);

  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen> {
  bool _allAgreed = false;
  bool _termsOfUse = false;
  bool _privacyPolicy = false;
  bool _marketingAgree = false;
  String _errorMessage = '';
  bool _isLoading = false;

  // 구글 로그인 데이터
  String? _googleToken;
  String? _googleEmail;
  String? _googleName;
  String? _googleId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 라우트 파라미터에서 구글 로그인 데이터 확인
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _googleToken = args['googleToken'] as String?;
      _googleEmail = args['email'] as String?;
      _googleName = args['name'] as String?;
      _googleId = args['googleId'] as String?;
    }
  }

  // 약관 동의 상태 변경 처리
  void _handleAgreementChange(String type, bool value) {
    setState(() {
      switch (type) {
        case 'all':
          _allAgreed = value;
          _termsOfUse = value;
          _privacyPolicy = value;
          _marketingAgree = value;
          break;
        case 'terms':
          _termsOfUse = value;
          _updateAllAgreedStatus();
          break;
        case 'privacy':
          _privacyPolicy = value;
          _updateAllAgreedStatus();
          break;
        case 'marketing':
          _marketingAgree = value;
          _updateAllAgreedStatus();
          break;
      }
    });
  }

  // 전체 동의 상태 업데이트
  void _updateAllAgreedStatus() {
    setState(() {
      _allAgreed = _termsOfUse && _privacyPolicy && _marketingAgree;
    });
  }

  // 계속하기 버튼 처리
  Future<void> _handleContinue() async {
    // 필수 약관 동의 확인
    if (!_termsOfUse || !_privacyPolicy) {
      setState(() {
        _errorMessage = '필수 약관에 동의해주세요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_googleToken != null) {
        // 구글 회원가입 처리
        final agreementData = {
          'termsOfUse': _termsOfUse,
          'privacyPolicy': _privacyPolicy,
          'marketingAgree': _marketingAgree,
        };

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.googleRegister(
          _googleToken!,
          agreementData,
          _googleId,
          _googleName,
        );

        if (success && mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // 일반 회원가입 - 회원가입 화면으로 이동
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/register',
            arguments: {
              'agreements': {
                'termsOfUse': _termsOfUse,
                'privacyPolicy': _privacyPolicy,
                'marketingAgree': _marketingAgree,
              },
            },
          );
        }
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('약관 동의'),
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
                if (_googleEmail != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '구글 계정: $_googleEmail',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 전체 동의
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _allAgreed,
                          onChanged: (value) => _handleAgreementChange('all', value ?? false),
                          activeColor: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '전체 동의',
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 이용약관 동의 (필수)
                _buildAgreementItem(
                  title: '이용약관 동의 (필수)',
                  content: _termsContent,
                  isChecked: _termsOfUse,
                  onChanged: (value) => _handleAgreementChange('terms', value ?? false),
                ),
                
                const SizedBox(height: 16),
                
                // 개인정보 수집 및 이용 동의 (필수)
                _buildAgreementItem(
                  title: '개인정보 수집 및 이용 동의 (필수)',
                  content: _privacyContent,
                  isChecked: _privacyPolicy,
                  onChanged: (value) => _handleAgreementChange('privacy', value ?? false),
                ),
                
                const SizedBox(height: 16),
                
                // 마케팅 정보 수신 동의 (선택)
                _buildAgreementItem(
                  title: '마케팅 정보 수신 동의 (선택)',
                  content: _marketingContent,
                  isChecked: _marketingAgree,
                  onChanged: (value) => _handleAgreementChange('marketing', value ?? false),
                ),
                
                const SizedBox(height: 24),
                
                if (_errorMessage.isNotEmpty)
                  ErrorMessageBox(message: _errorMessage),
                
                CommonButton(
                  text: _googleToken != null ? '구글로 회원가입 완료' : '다음',
                  onPressed: _handleContinue,
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 약관 항목 위젯
  Widget _buildAgreementItem({
    required String title,
    required String content,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 약관 제목 및 체크박스
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: isChecked,
                    onChanged: onChanged,
                    activeColor: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // 구분선
          const Divider(height: 1),
          
          // 약관 내용
          Container(
            padding: const EdgeInsets.all(16),
            height: 150,
            child: SingleChildScrollView(
              child: Text(
                content,
                style: AppTheme.bodySmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 이용약관 내용
  static const String _termsContent = '''
제1조 (목적)
이 약관은 LinguaEdge(이하 "회사"라 합니다)가 제공하는 서비스의 이용과 관련하여 회사와 회원과의 권리, 의무 및 책임사항, 기타 필요한 사항을 규정함을 목적으로 합니다.

제2조 (정의)
1. "서비스"라 함은 회사가 제공하는 모든 서비스를 의미합니다.
2. "회원"이라 함은 회사의 서비스에 접속하여 이 약관에 따라 회사와 이용계약을 체결하고 회사가 제공하는 서비스를 이용하는 고객을 말합니다.

제3조 (약관의 게시와 개정)
1. 회사는 이 약관의 내용을 회원이 쉽게 알 수 있도록 서비스 초기 화면에 게시합니다.
2. 회사는 관련법을 위배하지 않는 범위에서 이 약관을 개정할 수 있습니다.
''';

  // 개인정보 처리방침 내용
  static const String _privacyContent = '''
제1조 (개인정보의 수집 항목 및 이용 목적)
회사는 다음의 목적을 위하여 개인정보를 처리합니다. 처리하고 있는 개인정보는 다음의 목적 이외의 용도로는 이용되지 않으며, 이용 목적이 변경되는 경우에는 개인정보 보호법 제18조에 따라 별도의 동의를 받는 등 필요한 조치를 이행할 예정입니다.

1. 회원 가입 및 관리
- 회원 가입의사 확인, 회원제 서비스 제공에 따른 본인 식별·인증, 회원자격 유지·관리, 서비스 부정이용 방지, 각종 고지·통지, 고충처리 등을 목적으로 개인정보를 처리합니다.

2. 서비스 제공
- 콘텐츠 제공, 맞춤서비스 제공, 서비스 개선 등을 목적으로 개인정보를 처리합니다.

제2조 (개인정보의 보유 및 이용기간)
회사는 법령에 따른 개인정보 보유·이용기간 또는 정보주체로부터 개인정보를 수집 시에 동의 받은 개인정보 보유·이용기간 내에서 개인정보를 처리·보유합니다.
''';

  // 마케팅 정보 수신 동의 내용
  static const String _marketingContent = '''
LinguaEdge는 고객님께 더 나은 서비스와 다양한 혜택을 제공하기 위해 마케팅 정보를 제공하고자 합니다.

1. 수집 항목: 이메일 주소
2. 이용 목적: 신규 서비스 및 상품 안내, 이벤트 정보 제공, 혜택 및 광고성 정보 제공
3. 보유 기간: 회원 탈퇴 시 또는 마케팅 정보 수신 동의 철회 시까지

* 마케팅 정보 수신 동의는 선택사항이며, 동의하지 않더라도 LinguaEdge의 기본 서비스를 이용하실 수 있습니다.
* 마케팅 정보 수신 동의는 언제든지 회원정보 수정 페이지에서 변경하실 수 있습니다.
''';
}