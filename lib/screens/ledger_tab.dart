import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../categories.dart';
import '../models/household.dart';
import '../models/transaction_entry.dart';

/// 탭1: 금전출납부 — 잔액 + 최근 거래 목록
/// 상단 세그먼트로 [부부 통합 / 나만 / 배우자만] 필터 전환
class LedgerTab extends StatelessWidget {
  final Household household;
  final String myUid;
  final List<TxEntry> allTxs;
  final int startBalance; // 시작 잔액(이월 잔액) 설정값
  final void Function(TxType type) onAdd;
  final void Function(TxEntry tx) onDelete;
  final ValueChanged<Scope> onScopeChanged;
  final Scope scope;

  const LedgerTab({
    super.key,
    required this.household,
    required this.myUid,
    required this.allTxs,
    required this.startBalance,
    required this.onAdd,
    required this.onDelete,
    required this.onScopeChanged,
    required this.scope,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final now = DateTime.now();

    // 이번 달 + 스코프 필터
    final monthTxs = allTxs
        .where((t) => t.date.year == now.year && t.date.month == now.month)
        .toList();
    final partnerUid = household.partnerUidOf(myUid);
    final visible = switch (scope) {
      Scope.mine => monthTxs.where((t) => t.ownerUid == myUid).toList(),
      Scope.partner => monthTxs.where((t) => t.ownerUid == partnerUid).toList(),
      Scope.both => monthTxs,
    };

    var income = 0, expense = 0;
    for (final t in visible) {
      if (t.isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
    }
    final balance = startBalance + income - expense;

    // 잔액 = 시작잔액 + 전체(통합) 누적 수입 - 누적 지출
    var allIncome = 0, allExpense = 0;
    for (final t in allTxs) {
      if (t.isIncome) {
        allIncome += t.amount;
      } else {
        allExpense += t.amount;
      }
    }
    final totalBalance = startBalance + allIncome - allExpense;

    return Column(
      children: [
        // 스코프 필터
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: SegmentedButton<Scope>(
            segments: [
              const ButtonSegment(value: Scope.both, label: Text('우리 부부')),
              const ButtonSegment(value: Scope.mine, label: Text('나')),
              if (partnerUid != null)
                const ButtonSegment(value: Scope.partner, label: Text('배우자')),
            ],
            selected: {scope},
            onSelectionChanged: (s) => onScopeChanged(s.first),
          ),
        ),
        // 잔액 카드
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(scope == Scope.both ? '${household.name} 잔액' : '잔액',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${fmt.format(balance)} 원',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: balance >= 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    )),
                Text('총 잔액 ${fmt.format(totalBalance)} 원',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _sum('이번 달 수입', income, Colors.green),
                    _sum('이번 달 지출', expense, Colors.red),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 거래 목록
        Expanded(
          child: visible.isEmpty
              ? const Center(
                  child: Text('기록이 없어요.\n아래 + 버튼으로 첫 거래를 입력해 보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: visible.length,
                  itemBuilder: (context, i) {
                    final t = visible[i];
                    final cat = categoryOf(t.category, t.isIncome);
                    final isMine = t.ownerUid == myUid;
                    final owner = household.profileOf(t.ownerUid);
                    return Dismissible(
                      key: Key(t.id),
                      direction: isMine
                          ? DismissDirection.endToStart
                          : DismissDirection.none, // 배우자 거래는 삭제 불가
                      onDismissed: (_) => onDelete(t),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withOpacity(0.15),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        title: Text(t.category,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${DateFormat('M/d (E)', 'ko').format(t.date)}'
                          ' · ${owner.name}${t.note.isNotEmpty ? ' · ${t.note}' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${t.isIncome ? '+' : '-'}${fmt.format(t.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: t.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sum(String label, int value, Color color) => Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 2),
          Text('${NumberFormat('#,###').format(value)} 원',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      );
}

enum Scope { both, mine, partner }

/// 하단 FAB: 수입/지출 선택 다이얼로그 → 입력 화면
class LedgerFab extends StatelessWidget {
  final void Function(TxType type) onPicked;
  const LedgerFab({super.key, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (sheetCtx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.north, color: Colors.green),
                  title: const Text('수입 입력 (월급, 상여금 등)'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onPicked(TxType.income);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.south, color: Colors.red),
                  title: const Text('지출 입력'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onPicked(TxType.expense);
                  },
                ),
              ],
            ),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
