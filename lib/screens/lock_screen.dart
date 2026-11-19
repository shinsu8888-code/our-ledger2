import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/prefs_service.dart';

/// 앱 잠금 화면 (PIN 4자리)
class AppLock extends StatefulWidget {
  final Widget child;
  const AppLock({super.key, required this.child});

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> {
  String _input = '';
  bool _unlocked = false;

  void _tap(String d) {
    if (_input.length >= 4) return;
    setState(() => _input += d);
    if (_input.length == 4) {
      if (_input == Prefs.pin) {
        setState(() => _unlocked = true);
      } else {
        setState(() => _input = '');
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('비밀번호가 틀렸어요. 다시 입력해 주세요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48),
            const SizedBox(height: 12),
            const Text('비밀번호를 입력하세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      i < _input.length
                          ? Icons.circle
                          : Icons.circle_outlined,
                      size: 18,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            for (final row in [
              ['1', '2', '3'],
              ['4', '5', '6'],
              ['7', '8', '9'],
              ['', '0', '⌫'],
            ])
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final k in row)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SizedBox(
                        width: 72,
                        height: 56,
                        child: k.isEmpty
                            ? const SizedBox()
                            : OutlinedButton(
                                onPressed: () {
                                  if (k == '⌫') {
                                    if (_input.isNotEmpty) {
                                      setState(() => _input = _input
                                          .substring(0, _input.length - 1));
                                    }
                                  } else {
                                    _tap(k);
                                  }
                                },
                                child: Text(k,
                                    style: const TextStyle(fontSize: 20)),
                              ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// PIN 설정/변경 다이얼로그 (설정 탭에서 사용)
Future<void> showPinSetupDialog(BuildContext context) async {
  final c1 = TextEditingController();
  final c2 = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('앱 잠금 비밀번호'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: c1,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '새 비밀번호 4자리'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: c2,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: '비밀번호 확인'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('해제하기'), // PIN 제거
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('저장'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    if (c1.text.length == 4 && c1.text == c2.text) {
      Prefs.pin = c1.text;
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('앱 잠금이 설정되었어요.')));
      }
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호 4자리가 서로 같은지 확인해 주세요.')));
    }
  } else if (confirmed == false) {
    Prefs.pin = '';
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('앱 잠금을 해제했어요.')));
    }
  }
}
