import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../categories.dart';
import '../models/transaction_entry.dart';
import '../services/prefs_service.dart';

/// 수입/지출 입력 화면 (한 화면에서 수입·지출 스위치)
/// 메모를 입력하면 자동 분류 규칙(키워드→카테고리)으로 카테고리를 자동 추천
class AddEditScreen extends StatefulWidget {
  final bool isIncome;
  final void Function(TxType type, String category, int amount, String note, DateTime date)
      onSubmit;

  const AddEditScreen({super.key, required this.isIncome, required this.onSubmit});

  @override
  State<AddEditScreen> createState() => _AddEditScreenState();
}

class _AddEditScreenState extends State<AddEditScreen> {
  late bool _income = widget.isIncome;
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  late String _selectedCategory =
      (_income ? incomeCategories : expenseCategories).first.name;
  bool _autoPicked = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _onNoteChanged(String v) {
    if (v.trim().isEmpty) {
      _autoPicked = false;
      return;
    }
    final suggested = Prefs.suggestCategory(v, isIncome: _income);
    final cats = _income ? incomeCategories : expenseCategories;
    final isDefault =
        _selectedCategory == cats.first.name || _autoPicked;
    if (isDefault && cats.any((c) => c.name == suggested)) {
      setState(() {
        _selectedCategory = suggested;
        _autoPicked = true;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final amount = int.tryParse(_amount.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('금액을 입력해 주세요.')));
      return;
    }
    Navigator.of(context).pop();
    widget.onSubmit(
      _income ? TxType.income : TxType.expense,
      _selectedCategory,
      amount,
      _note.text.trim(),
      _date,
    );
  }
  @override
  Widget build(BuildContext context) {
    final cats = _income ? incomeCategories : expenseCategories;
    // 수입/지출 전환 시 카테고리가 목록에 있는지 보정
    if (!cats.any((c) => c.name == _selectedCategory)) {
      _selectedCategory = cats.first.name;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_income ? '수입 입력' : '지출 입력'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.south), label: Text('지출')),
                ButtonSegment(value: true, icon: Icon(Icons.north), label: Text('수입')),
              ],
              selected: {_income},
              onSelectionChanged: (s) => setState(() => _income = s.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: '금액',
                suffixText: '원',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 20),

            const Text('카테고리',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in cats)
                  ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(c.icon, size: 16, color: c.color),
                        const SizedBox(width: 4),
                        Text(c.name),
                      ],
                    ),
                    selected: _selectedCategory == c.name,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = c.name),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _note,
              onChanged: _onNoteChanged,
              decoration: const InputDecoration(
                labelText: '메모 (선택) — 입력하면 카테고리를 자동 추천해요',
                prefixIcon: Icon(Icons.edit_note),
              ),
            ),
            const SizedBox(height: 20),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('날짜'),
              trailing: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko').format(_date)),
              onTap: _pickDate,
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('저장', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
