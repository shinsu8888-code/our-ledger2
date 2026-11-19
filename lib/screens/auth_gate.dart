import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/app_mode.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// 로그인 상태에 따라 로그인 화면 또는 메인 화면으로 분기
/// (Firebase 설정 전에는 오프라인 모드로 바로 진입)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppMode.cloud) {
      return const HomeShell(uid: 'local', displayName: '나');
    }
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        return user == null
            ? const LoginScreen()
            : HomeShell(uid: user.uid, displayName: user.email ?? '나');
      },
    );
  }
}
