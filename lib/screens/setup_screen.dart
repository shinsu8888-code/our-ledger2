import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/household_service.dart';

/// 첫 로그인 후: 가계부 만들기 or 초대코드로 참여하기
/// (이름/월급도 여기서 입력)
class SetupScreen extends StatefulWidget {
  final HouseholdService service;
  const SetupScreen({super.key, required this.service});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _name = TextEditingController();
  final _salary = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return _err('이름을 입력해 주세요.');
    final salary = int.tryParse(_salary.text.replaceAll(',', '')) ?? -1;
    if (salary < 0) return _err('월급을 숫자로 입력해 주세요.');
    await _run(() => widget.service.createHousehold(
          householdName: '우리집 가계부',
          myName: name,
          mySalary: salary,
        ));
  }

  Future<void> _join() async {
    final name = _name.text.trim();
    if (name.isEmpty) return _err('이름을 입력해 주세요.');
    if (_code.text.trim().length < 4) return _err('배우자가 알려준 초대코드를 입력해 주세요.');
    final salary = int.tryParse(_salary.text.replaceAll(',', '')) ?? -1;
    if (salary < 0) return _err('월급을 숫자로 입력해 주세요.');
    await _run(() => widget.service.joinByCode(
          code: _code.text,
          myName: name,
          mySalary: salary,
        ));
  }

  Future<void> _run(Future<Object?> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      // 성공 시 HomeShell이 스트림으로 자동 전환
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(String msg) => setState(() => _error = msg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시작하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 내 정보
            _section('내 정보'),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: '내 이름 (예: 남편 / 아내)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _salary,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '나의 월급 (원) — 매달 고정 수입',
                suffixText: '원',
              ),
            ),
            const SizedBox(height: 32),

            // 가계부 만들기
            _section('새 가계부 만들기'),
            const Text('먼저 시작하는 분이 만들고, 초대코드를 배우자에게 알려주세요.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _create,
              icon: const Icon(Icons.add_home),
              label: const Text('가계부 만들기'),
            ),
            const SizedBox(height: 32),

            // 초대코드로 참여
            _section('초대코드로 참여하기'),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: '초대코드 6자리 (예: K7RM2P)',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _busy ? null : _join,
              icon: const Icon(Icons.group_add),
              label: const Text('배우자 가계부에 참여하기'),
            ),

            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
}
