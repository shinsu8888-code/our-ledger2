import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../categories.dart';
import '../models/recurring.dart';
import '../services/prefs_service.dart';

/// 정기입출금 관리 화면 (월급, 월세, 통신비 등 매달 반복 기록)
class RecurringScreen extends StatefulWidget {
  const RecurringScreen({super.key});

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  @override
  Widget build(BuildContext context) {
    final list = Prefs.recurrings;
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(title: const Text('정기입출금 관리')),
      body: list.isEmpty
          ? const Center(
              child: Text('등록된 반복 기록이 없어요.\n+ 버튼으로 월급이나 고정지출을 등록하면\n매달 자동으로 기록돼요!',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final r in list)
                  ListTile(
                    leading: Icon(
                      r.isIncome ? Icons.north : Icons.south,
                      color: r.isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text('${r.category} · ${fmt.format(r.amount)} 원'),
                    subtitle: Text(
                        '매달 ${r.dayOfMonth}일${r.note.isNotEmpty ? ' · ${r.note}' : ''}'
                        '${r.lastApplied.isNotEmpty ? ' · 마지막: ${r.lastApplied}' : ''}',
                        style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        final l = Prefs.recurrings..removeWhere((e) => e.id == r.id);
                        Prefs.setRecurrings(l);
                        setState(() {});
                      },
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _add() async {
    final amountC = TextEditingController();
    final noteC = TextEditingController();
    final dayC = TextEditingController(text: '25');
    var isIncome = false;
    var category = expenseCategories.first.name;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('정기입출금 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('지출')),
                    ButtonSegment(value: true, label: Text('수입')),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (s) => setD(() {
                    isIncome = s.first;
                    category =
                        (isIncome ? incomeCategories : expenseCategories).first.name;
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: '금액 (원)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: category,
                  items: [
                    for (final c in isIncome ? incomeCategories : expenseCategories)
                      DropdownMenuItem(value: c.name, child: Text(c.name)),
                  ],
                  onChanged: (v) => setD(() => category = v ?? category),
                  decoration: const InputDecoration(labelText: '카테고리'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteC,
                  decoration: const InputDecoration(labelText: '메모 (예: 월급, 월세)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dayC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      labelText: '매달 며칠에 기록할까요?', suffixText: '일'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('취소')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('저장')),
          ],
        ),
      ),
    );

    if (ok != true) return;
    final amount = int.tryParse(amountC.text.replaceAll(',', ''));
    final day = int.tryParse(dayC.text) ?? 1;
    if (amount == null || amount <= 0 || day < 1 || day > 28) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('금액을 입력하고, 날짜는 1~28일 사이로 입력해 주세요.')));
      }
      return;
    }
    final list = Prefs.recurrings
      ..add(RecurringEntry(
        id: PendingCapture.newId(),
        isIncome: isIncome,
        category: category,
        amount: amount,
        note: noteC.text.trim(),
        dayOfMonth: day,
      ));
    Prefs.setRecurrings(list);
    setState(() {});
  }
}
