import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false; // false: 로그인, true: 회원가입
  bool _busy = false;
  String? _error;

  Future<void> _submit() async {
    // 빈 값으로 API를 호출하지 않도록 먼저 확인
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 모두 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      // 성공하면 AuthGate(StreamBuilder)가 자동으로 메인 화면으로 전환
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = switch (e.code) {
          'invalid-email' => '이메일 형식이 올바르지 않아요.',
          'email-already-in-use' => '이미 가입된 이메일이에요. 로그인해 주세요.',
          'weak-password' => '비밀번호를 6자 이상으로 설정해 주세요.',
          'invalid-credential' || 'wrong-password' || 'user-not-found' =>
            '이메일 또는 비밀번호가 올바르지 않아요.',
          'invalid-login-credentials' => '이메일 또는 비밀번호가 올바르지 않아요.',
          // Firebase 원인까지 보이게: 코드 + 상세 메시지
          _ => '오류: ${e.code}${e.message == null ? '' : '\n(${e.message})'}',
        };
      });
    } catch (e) {
      setState(() => _error = '오류가 발생했어요: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 64, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                const Text(
                  '우리집 가계부',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  '금전출납 · 부부 통합 관리',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호 (6자 이상)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(_busy
                      ? '처리 중...'
                      : (_isSignUp ? '회원가입' : '로그인')),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _isSignUp = !_isSignUp;
                            _error = null;
                          }),
                  child: Text(_isSignUp
                      ? '이미 계정이 있어요 → 로그인'
                      : '처음이신가요? → 회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
