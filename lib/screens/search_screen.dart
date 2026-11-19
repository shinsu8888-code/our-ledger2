import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../categories.dart';
import '../models/household.dart';
import '../models/transaction_entry.dart';

/// 통합 검색: 메모/카테고리/금액으로 거래 찾기
class SearchScreen extends StatefulWidget {
  final Household household;
  final String myUid;
  final List<TxEntry> allTxs;

  const SearchScreen({
    super.key,
    required this.household,
    required this.myUid,
    required this.allTxs,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  String _type = '전체'; // 전체 / 수입 / 지출
  String _owner = '전체'; // 전체 / 나 / 배우자

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final partnerUid = widget.household.partnerUidOf(widget.myUid);
    final keyword = _query.text.trim().toLowerCase();

    final results = widget.allTxs.where((t) {
      if (_type == '수입' && !t.isIncome) return false;
      if (_type == '지출' && t.isIncome) return false;
      if (_owner == '나' && t.ownerUid != widget.myUid) return false;
      if (_owner == '배우자' && t.ownerUid != partnerUid) return false;
      if (keyword.isEmpty) return true;
      return t.note.toLowerCase().contains(keyword) ||
          t.category.contains(keyword) ||
          fmt.format(t.amount).contains(keyword) ||
          t.amount.toString().contains(keyword);
    }).toList();

    var sumIncome = 0, sumExpense = 0;
    for (final t in results) {
      if (t.isIncome) {
        sumIncome += t.amount;
      } else {
        sumExpense += t.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('거래 검색')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '메모, 카테고리, 금액으로 검색',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final t in const ['전체', '수입', '지출'])
                        ChoiceChip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                    ],
                  ),
                ),
                if (partnerUid != null)
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      children: [
                        for (final o in const ['전체', '나', '배우자'])
                          ChoiceChip(
                            label: Text(o, style: const TextStyle(fontSize: 12)),
                            selected: _owner == o,
                            onSelected: (_) => setState(() => _owner = o),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('결과 ${results.length}건',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('수입 +${fmt.format(sumIncome)} · 지출 -${fmt.format(sumExpense)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text('검색 결과가 없어요.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, i) {
                      final t = results[i];
                      final cat = categoryOf(t.category, t.isIncome);
                      final owner = widget.household.profileOf(t.ownerUid);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cat.color.withOpacity(0.15),
                          child: Icon(cat.icon, color: cat.color, size: 20),
                        ),
                        title: Text(t.category),
                        subtitle: Text(
                          '${DateFormat('yyyy/M/d (E)', 'ko').format(t.date)}'
                          ' · ${owner.name}${t.note.isNotEmpty ? ' · ${t.note}' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Text(
                          '${t.isIncome ? '+' : '-'}${fmt.format(t.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: t.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
