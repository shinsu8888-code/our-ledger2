import 'package:flutter/material.dart';

import '../models/household.dart';
import '../models/transaction_entry.dart';
import '../services/app_mode.dart';
import '../services/auto_capture.dart';
import '../services/household_service.dart';
import '../services/local_backend.dart';
import '../services/prefs_service.dart';
import '../services/recurring_service.dart';
import 'add_edit_screen.dart';
import 'budget_tab.dart';
import 'ledger_tab.dart';
import 'pending_capture_screen.dart';
import 'report_tab.dart';
import 'search_screen.dart';
import 'settings_tab.dart';
import 'setup_screen.dart';

/// 로그인(또는 오프라인 진입) 후 메인 셸
/// 탭: 금전출납부 / 예산 / 보고서 / 설정
class HomeShell extends StatelessWidget {
  final String uid;
  final String displayName;
  const HomeShell({super.key, required this.uid, required this.displayName});

  @override
  Widget build(BuildContext context) {
    final service = HouseholdService(uid);

    return FutureBuilder<Household?>(
      future: service.loadMyHousehold(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final household = snap.data;
        if (household == null) {
          return SetupScreen(service: service);
        }
        return _Home(household: household, service: service);
      },
    );
  }
}

class _Home extends StatefulWidget {
  final Household household;
  final HouseholdService service;
  const _Home({required this.household, required this.service});

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int _tab = 0;
  Scope _scope = Scope.both;
  late Household household = widget.household;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // 카드/은행 알림 자동가져오기 시작 (권한 있을 때만 동작)
    AutoCapture.onChanged = () {
      if (mounted) setState(() {});
    };
    await AutoCapture.init();

    // 정기입출금 중 이번 달 미반영 항목 자동 기록
    final applied = await RecurringService.applyAll(
      householdId: household.id,
      ownerUid: widget.service.uid,
      addTx: (isIncome, category, amount, note) async {
        await TxRepository(household.id).add(TxEntry(
          id: '',
          type: isIncome ? TxType.income : TxType.expense,
          category: category,
          amount: amount,
          note: note,
          date: DateTime.now(),
          ownerUid: widget.service.uid,
          createdAt: DateTime.now(),
        ));
      },
    );
    if (applied > 0) {
      await RecurringService.show(
          '정기입출금 자동기록', '이번 달 정기입출금 $applied건이 기록되었어요.');
    }
    if (mounted) setState(() {});
  }

  Stream<List<TxEntry>> get _txStream =>
      TxRepository(household.id).stream();

  Future<void> _addTx(TxType type) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AddEditRoute(
        householdId: household.id,
        ownerUid: widget.service.uid,
        isIncome: type == TxType.income,
      ),
    ));
  }

  Future<void> _addDirect(
      bool isIncome, String category, int amount, String note) async {
    await TxRepository(household.id).add(TxEntry(
      id: '',
      type: isIncome ? TxType.income : TxType.expense,
      category: category,
      amount: amount,
      note: note,
      date: DateTime.now(),
      ownerUid: widget.service.uid,
      createdAt: DateTime.now(),
    ));
  }

  Future<void> _reloadHousehold() async {
    final h = await widget.service.loadMyHousehold();
    if (h != null && mounted) setState(() => household = h);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TxEntry>>(
      stream: _txStream,
      initialData: AppMode.cloud ? null : LocalStore.instance.current,
      builder: (context, snap) {
        final txs = snap.data ?? const <TxEntry>[];
        final pendingCount = Prefs.pending.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppMode.cloud ? '우리집 가계부' : '우리집 가계부 (내 폰 전용)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                tooltip: '거래 검색',
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SearchScreen(
                    household: household,
                    myUid: widget.service.uid,
                    allTxs: txs,
                  ),
                )),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.sms_outlined),
                    tooltip: '자동입력 대기',
                    onPressed: () => Navigator.of(context)
                        .push(MaterialPageRoute(
                          builder: (_) => PendingCaptureScreen(
                            ownerUid: widget.service.uid,
                            onAdd: _addDirect,
                          ),
                        ))
                        .then((_) => setState(() {})),
                  ),
                  if (pendingCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Text('$pendingCount',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: switch (_tab) {
            0 => LedgerTab(
                household: household,
                myUid: widget.service.uid,
                allTxs: txs,
                startBalance: Prefs.startBalance,
                onAdd: _addTx,
                onDelete: (tx) async =>
                    TxRepository(household.id).delete(tx.id),
                onScopeChanged: (s) => setState(() => _scope = s),
                scope: _scope,
              ),
            1 => BudgetTab(
                household: household,
                myUid: widget.service.uid,
                allTxs: txs,
              ),
            2 => ReportTab(
                household: household,
                myUid: widget.service.uid,
                allTxs: txs,
              ),
            _ => SettingsTab(
                household: household,
                service: widget.service,
                allTxs: txs,
                startBalance: Prefs.startBalance,
                onStartBalanceChanged: (v) => setState(() {}),
                onProfileUpdated: _reloadHousehold,
              ),
          },
          floatingActionButton:
              _tab == 0 ? LedgerFab(onPicked: _addTx) : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: '출납부'),
              NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: '예산'),
              NavigationDestination(
                  icon: Icon(Icons.insights_outlined),
                  selectedIcon: Icon(Icons.insights),
                  label: '보고서'),
              NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: '설정'),
            ],
          ),
        );
      },
    );
  }
}

/// AddEditScreen 라우트 (저장 콜백을 저장소에 연결)
class AddEditRoute extends StatelessWidget {
  final String householdId;
  final String ownerUid;
  final bool isIncome;

  const AddEditRoute({
    super.key,
    required this.householdId,
    required this.ownerUid,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return AddEditScreen(
      isIncome: isIncome,
      onSubmit: (type, category, amount, note, date) async {
        await TxRepository(householdId).add(TxEntry(
          id: '',
          type: type,
          category: category,
          amount: amount,
          note: note,
          date: date,
          ownerUid: ownerUid,
          createdAt: DateTime.now(),
        ));
      },
    );
  }
}
