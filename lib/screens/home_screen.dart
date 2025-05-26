import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
 const HomeScreen({Key? key}) : super(key: key);

 @override
 Widget build(BuildContext context) {
   final authProvider = Provider.of<AuthProvider>(context);
   final user = authProvider.user;

   return Scaffold(
     appBar: AppBar(
       title: const Text('LinguaEdge'),
       actions: [
         IconButton(
           icon: const Icon(Icons.logout),
           onPressed: () async {
             await authProvider.logout();
             if (context.mounted) {
               Navigator.pushReplacementNamed(context, '/login');
             }
           },
           tooltip: '로그아웃',
         ),
       ],
     ),
     body: Center(
       child: Column(
         mainAxisAlignment: MainAxisAlignment.center,
         children: [
           Text(
             '환영합니다, ${user?.username ?? '사용자'}님!',
             style: AppTheme.titleLarge,
             textAlign: TextAlign.center,
           ),
           const SizedBox(height: 16),
           Text(
             '이메일: ${user?.email ?? ''}',
             style: AppTheme.bodyLarge,
           ),
           const SizedBox(height: 8),
           Text(
             '사용자 타입: ${user?.isSocialUser ?? false ? '소셜 로그인' : '일반 계정'}',
             style: AppTheme.bodyLarge,
           ),
           const SizedBox(height: 8),
           Text(
             '프리미엄 여부: ${user?.isPremium ?? false ? '프리미엄' : '무료'}',
             style: AppTheme.bodyLarge,
           ),
           const SizedBox(height: 24),
           
           // 마이페이지 버튼 추가
           ElevatedButton.icon(
             onPressed: () {
               Navigator.pushNamed(context, '/profile');
             },
             icon: const Icon(Icons.person),
             label: const Text('마이페이지'),
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
             ),
           ),
           
           const SizedBox(height: 16),
           
           // 퀴즈 생성 버튼 추가
           ElevatedButton.icon(
             onPressed: () {
               Navigator.pushNamed(context, '/quizzes');
             },
             icon: const Icon(Icons.quiz),
             label: const Text('퀴즈 관리'),
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
               backgroundColor: AppTheme.secondaryColor,
             ),
           ),
           
           const SizedBox(height: 16),
           
           // 알람 설정 버튼 추가
           ElevatedButton.icon(
             onPressed: () {
               Navigator.pushNamed(context, '/alarms');
             },
             icon: const Icon(Icons.alarm),
             label: const Text('알람 설정'),
             style: ElevatedButton.styleFrom(
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
               backgroundColor: Colors.orange,
             ),
           ),
           
           const SizedBox(height: 24),
           
           ElevatedButton(
             onPressed: () {
               Navigator.pushNamed(context, '/change-password');
             },
             child: const Text('비밀번호 변경'),
           ),
           const SizedBox(height: 16),
           ElevatedButton(
             onPressed: () {
               Navigator.pushNamed(context, '/delete-account');
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.errorColor,
             ),
             child: const Text('계정 삭제'),
           ),
         ],
       ),
     ),
   );
 }
}