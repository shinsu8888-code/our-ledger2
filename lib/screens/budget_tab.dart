import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../categories.dart';
import '../models/household.dart';
import '../models/transaction_entry.dart';
import '../services/prefs_service.dart';

/// 예산 탭: 카테고리별 월 예산 대비 사용액, 초과 경고
class BudgetTab extends StatefulWidget {
  final Household household;
  final String myUid;
  final List<TxEntry> allTxs;

  const BudgetTab({
    super.key,
    required this.household,
    required this.myUid,
    required this.allTxs,
  });

  @override
  State<BudgetTab> createState() => _BudgetTabState();
}

class _BudgetTabState extends State<BudgetTab> {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fmt = NumberFormat('#,###');

    // 이번 달 지출(부부 통합) 카테고리별 집계
    final spent = <String, int>{};
    var totalSpent = 0, totalBudget = 0;
    for (final t in widget.allTxs) {
      if (t.isIncome) continue;
      if (t.date.year != now.year || t.date.month != now.month) continue;
      spent.update(t.category, (v) => v + t.amount, ifAbsent: () => t.amount);
    }

    final budgets = Prefs.budgets;
    budgets.forEach((_, v) => totalBudget += v);
    budgets.forEach((k, _) => totalSpent += spent[k] ?? 0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('이번 달 전체 예산',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${fmt.format(totalBudget)} 원',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: totalBudget == 0
                      ? 0
                      : (totalSpent / totalBudget).clamp(0.0, 1.0),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(6),
                  color: totalSpent > totalBudget
                      ? Colors.red
                      : totalSpent > totalBudget * 0.8
                          ? Colors.orange
                          : Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  '사용 ${fmt.format(totalSpent)} 원'
                  '${totalBudget > 0 ? ' · 남음 ${fmt.format((totalBudget - totalSpent).clamp(0, 1 << 62))} 원' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: totalSpent > totalBudget ? Colors.red : null,
                  ),
                ),
                if (totalSpent > totalBudget)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('⚠️ 이번 달 예산을 초과했어요!',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('카테고리별 예산 (부부 합산 지출 기준)',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final c in expenseCategories) _budgetRow(c, spent, budgets, fmt),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _budgetRow(CategoryDef c, Map<String, int> spent,
      Map<String, int> budgets, NumberFormat fmt) {
    final budget = budgets[c.name] ?? 0;
    final used = spent[c.name] ?? 0;
    final over = budget > 0 && used > budget;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(c.icon, color: c.color),
        title: Text(c.name),
        subtitle: budget > 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: (used / budget).clamp(0.0, 1.0),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                    color: over ? Colors.red : c.color,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${fmt.format(used)} / ${fmt.format(budget)} 원'
                    '${over ? ' · ${fmt.format(used - budget)}원 초과!' : ''}',
                    style: TextStyle(
                        fontSize: 12,
                        color: over ? Colors.red : Colors.grey,
                        fontWeight: over ? FontWeight.bold : null),
                  ),
                ],
              )
            : Text('사용 ${fmt.format(used)} 원 · 예산 미설정',
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _editBudget(c.name, budget),
        ),
      ),
    );
  }

  Future<void> _editBudget(String category, int current) async {
    final c = TextEditingController(
        text: current == 0 ? '' : current.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$category 월 예산'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: '원'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, 0),
              child: const Text('삭제')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx,
                  int.tryParse(c.text.replaceAll(',', '')) ?? 0),
              child: const Text('저장')),
        ],
      ),
    );
    if (result != null) {
      Prefs.setBudget(category, result);
      setState(() {});
    }
  }
}
