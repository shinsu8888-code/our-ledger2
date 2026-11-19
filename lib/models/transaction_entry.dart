import 'package:cloud_firestore/cloud_firestore.dart';

enum TxType { income, expense }

/// 한 건의 거래(수입 또는 지출)
class TxEntry {
  final String id;
  final TxType type;
  final String category;
  final int amount;
  final String note;
  final DateTime date;
  final String ownerUid; // 등록한 사람 (나 / 배우자)
  final DateTime createdAt;

  const TxEntry({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.ownerUid,
    required this.createdAt,
  });

  bool get isIncome => type == TxType.income;

  factory TxEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return TxEntry(
      id: doc.id,
      type: d['type'] == 'income' ? TxType.income : TxType.expense,
      category: (d['category'] as String?) ?? '기타 지출',
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      note: (d['note'] as String?) ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ownerUid: (d['ownerUid'] as String?) ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'type': isIncome ? 'income' : 'expense',
        'category': category,
        'amount': amount,
        'note': note,
        'date': Timestamp.fromDate(date),
        'ownerUid': ownerUid,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
