import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_gate.dart';
import 'screens/lock_screen.dart';
import 'services/app_mode.dart';
import 'services/prefs_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  await _initFirebase();
  runApp(const BootApp());
}

/// Firebase 설정 여부에 따라 모드 결정
/// - lib/firebase_options.dart 가 실제 설정값으로 교체되어 있으면 클라우드(부부 동기화)
/// - 템플릿 그대로면 오프라인 모드(내 폰 전용)
Future<void> _initFirebase() async {
  try {
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (opts.projectId == 'replace-me' || opts.apiKey.contains('REPLACE')) {
      AppMode.cloud = false; // 설정 전 → 오프라인 모드
      return;
    }
    await Firebase.initializeApp(options: opts);
    AppMode.cloud = true;
  } catch (_) {
    AppMode.cloud = false;
  }
}

class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.mode,
      builder: (context, mode, _) => MaterialApp(
        title: '우리집 가계부',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(false),
        darkTheme: buildTheme(true),
        themeMode: mode,
        home: const _Ready(child: AuthGate()),
      ),
    );
  }
}

/// PIN 설정 시 잠금 화면 먼저
class _Ready extends StatelessWidget {
  final Widget child;
  const _Ready({required this.child});

  @override
  Widget build(BuildContext context) {
    if (Prefs.pin.isNotEmpty) return AppLock(child: child);
    return child;
  }
}
