import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/household.dart';
import '../models/transaction_entry.dart';
import '../services/app_mode.dart';
import '../services/auto_capture.dart';
import '../services/backup_service.dart';
import '../services/household_service.dart';
import '../services/prefs_service.dart';
import '../services/recurring_service.dart';
import '../theme.dart';
import 'lock_screen.dart';
import 'recurring_screen.dart';

/// 설정 탭 — 초대코드/프로필·월급/시작잔액/화면/보안/알림/자동입력/백업
class SettingsTab extends StatefulWidget {
  final Household household;
  final HouseholdService service;
  final List<TxEntry> allTxs;
  final int startBalance;
  final ValueChanged<int> onStartBalanceChanged;
  final VoidCallback onProfileUpdated;

  const SettingsTab({
    super.key,
    required this.household,
    required this.service,
    required this.allTxs,
    required this.startBalance,
    required this.onStartBalanceChanged,
    required this.onProfileUpdated,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late final TextEditingController _startBalance =
      TextEditingController(text: NumberFormat('#,###').format(widget.startBalance));
  late final TextEditingController _name =
      TextEditingController(text: _me.name);
  late final TextEditingController _salary = TextEditingController(
      text: _me.monthlySalary == 0 ? '' : _me.monthlySalary.toString());

  MemberProfile get _me => widget.household.profileOf(widget.service.uid);

  @override
  void dispose() {
    _startBalance.dispose();
    _name.dispose();
    _salary.dispose();
    super.dispose();
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.household.inviteCode));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대코드를 복사했어요. 배우자에게 공유해 주세요!')));
    }
  }

  Future<void> _saveProfile() async {
    final name = _name.text.trim();
    final salary = int.tryParse(_salary.text.replaceAll(',', ''));
    if (name.isEmpty || salary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이름과 월급을 올바르게 입력해 주세요.')));
      return;
    }
    await widget.service.updateMyProfile(
        household: widget.household, name: name, salary: salary);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장했어요.')));
      widget.onProfileUpdated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final myUid = widget.service.uid;
    final partnerUid =
        AppMode.cloud ? widget.household.partnerUidOf(myUid) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- 공유 (클라우드 모드만) ----
        if (AppMode.cloud) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.vpn_key),
              title: const Text('초대코드'),
              subtitle: Text(widget.household.inviteCode,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4)),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _copyCode,
                tooltip: '복사',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            partnerUid == null
                ? '아직 혼자예요. 위 초대코드를 배우자에게 보내면, 배우자가 앱 첫 화면에서 "초대코드로 참여하기"를 눌러 함께 쓸 수 있어요.'
                : '함께 쓰는 사람: ${widget.household.profileOf(partnerUid).name}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
        ],

        // ---- 시작 잔액 ----
        _title('시작 잔액 (이월 잔액)'),
        TextField(
          controller: _startBalance,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '가계부 시작 시점의 통장 잔액',
            suffixText: '원',
            prefixIcon: Icon(Icons.account_balance),
          ),
          onChanged: (v) => widget.onStartBalanceChanged(
              int.tryParse(v.replaceAll(',', '')) ?? 0),
        ),
        const SizedBox(height: 24),

        // ---- 내 프로필/월급 ----
        _title('내 프로필 · 월급'),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: '내 이름'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _salary,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: '나의 월급 (매달 고정 수입)',
            suffixText: '원',
            prefixIcon: Icon(Icons.payments),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: _saveProfile,
          child: const Text('프로필 저장'),
        ),
        const SizedBox(height: 24),

        // ---- 부부 급여 현황 ----
        if (partnerUid != null) ...[
          _title('우리 부부 월급 현황'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('나', _me.monthlySalary),
                  _row(widget.household.profileOf(partnerUid).name,
                      widget.household.profileOf(partnerUid).monthlySalary),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('합계',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${fmt.format(_me.monthlySalary + widget.household.profileOf(partnerUid).monthlySalary)} 원',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // ---- 화면 ----
        _title('화면'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('다크 모드'),
          value: Prefs.darkMode,
          onChanged: (v) {
            Prefs.darkMode = v;
            AppTheme.mode.value = v ? ThemeMode.dark : ThemeMode.light;
            setState(() {});
          },
        ),
        const Divider(),

        // ---- 보안 ----
        _title('보안'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.lock_outline),
          title: const Text('앱 잠금 비밀번호 (PIN 4자리)'),
          subtitle: Text(Prefs.pin.isEmpty ? '꺼짐' : '설정됨',
              style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showPinSetupDialog(context),
        ),
        const Divider(),

        // ---- 알림 · 자동입력 ----
        _title('알림 · 자동입력'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.repeat),
          title: const Text('정기입출금 관리'),
          subtitle: const Text('월급·월세 등을 매달 자동 기록',
              style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecurringScreen())),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_active_outlined),
          title: const Text('알림 권한 허용'),
          subtitle: const Text('정기입출금 자동기록 알림 받기',
              style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await RecurringService.requestPermission();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('알림 권한을 요청했어요. 허용해 주세요.')));
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sms_outlined),
          title: const Text('결제 알림 자동가져오기 권한'),
          subtitle: const Text(
              '카드/은행 알림을 읽어 입력을 자동으로 채워줍니다 (기기 안에서만 처리)',
              style: TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await AutoCapture.openPermissionSettings();
          },
        ),
        const Divider(),

        // ---- 백업 · 내보내기 ----
        _title('백업 · 내보내기'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.table_view),
          title: const Text('엑셀(CSV)로 내보내기'),
          subtitle: const Text('거래 전체를 엑셀에서 열 수 있는 파일로 저장',
              style: TextStyle(fontSize: 12)),
          onTap: () => BackupService.exportCsv(
              context, widget.allTxs, widget.household),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.upload_file),
          title: const Text('엑셀(CSV)에서 가져오기'),
          subtitle: const Text('날짜,구분,카테고리,금액,메모 형식의 CSV 불러오기',
              style: TextStyle(fontSize: 12)),
          onTap: () async {
            final n = await BackupService.importCsv(
              householdId: widget.household.id,
              ownerUid: widget.service.uid,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$n건을 가져왔어요.')));
            }
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.backup_outlined),
          title: const Text('백업 파일 공유 (JSON)'),
          onTap: () => BackupService.shareJson(
            context,
            BackupService.exportJson(
                widget.allTxs, widget.household, widget.startBalance),
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.restore),
          title: const Text('백업 파일 복원'),
          onTap: () async {
            final n = await BackupService.restoreJson(
              householdId: widget.household.id,
              ownerUid: widget.service.uid,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$n건을 복원했어요.')));
            }
          },
        ),
        const Divider(),

        // ---- 기타 ----
        if (AppMode.cloud)
          OutlinedButton.icon(
            onPressed: () => widget.service.signOut(),
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
          ),
        if (!AppMode.cloud)
          const Text(
            '오프라인 모드로 사용 중이에요. (내 폰 전용)\n부부 동기화를 원하면 빌드 가이드의 Firebase 연결 단계 후 재빌드하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _row(String name, int salary) {
    final fmt = NumberFormat('#,###');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 14)),
          Text('${fmt.format(salary)} 원',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
}
