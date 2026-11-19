import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/prefs_service.dart';

/// 자동입력 대기 목록: 카드/은행 알림에서 읽어온 항목 확인 후 기록
class PendingCaptureScreen extends StatelessWidget {
  final String ownerUid;
  final Future<void> Function(bool isIncome, String category, int amount, String note)
      onAdd;

  const PendingCaptureScreen({super.key, required this.ownerUid, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final list = Prefs.pending;
    final fmt = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: const Text('자동입력 대기 목록'),
        actions: [
          if (list.isNotEmpty)
            TextButton(
              onPressed: () async {
                final items = Prefs.pending;
                for (final p in items) {
                  await onAdd(p.isIncome,
                      Prefs.suggestCategory(p.note, isIncome: p.isIncome),
                      p.amount, p.note);
                }
                Prefs.setPending([]);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${items.length}건을 모두 기록했어요.')));
                  Navigator.pop(context);
                }
              },
              child: const Text('모두 기록'),
            ),
        ],
      ),
      body: list.isEmpty
          ? const Center(
              child: Text('대기 중인 항목이 없어요.\n폰에 결제·출금 알림이 오면 여기에 자동으로 쌓여요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)))
          : ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final p in list)
                  ListTile(
                    leading: Icon(
                      p.isIncome ? Icons.north : Icons.south,
                      color: p.isIncome ? Colors.green : Colors.red,
                    ),
                    title: Text(
                        '${p.isIncome ? '+' : '-'}${fmt.format(p.amount)} 원'
                        '${p.bank.isNotEmpty ? ' (${p.bank})' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${DateFormat('M/d HH:mm').format(DateTime.fromMillisecondsSinceEpoch(p.ts))}\n${p.note}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check,
                              color: Colors.green, size: 22),
                          tooltip: '기록하기',
                          onPressed: () async {
                            await onAdd(p.isIncome,
                                Prefs.suggestCategory(p.note, isIncome: p.isIncome),
                                p.amount, p.note);
                            final l = Prefs.pending..removeWhere((e) => e.id == p.id);
                            Prefs.setPending(l);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.grey, size: 22),
                          tooltip: '버리기',
                          onPressed: () {
                            final l = Prefs.pending..removeWhere((e) => e.id == p.id);
                            Prefs.setPending(l);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
