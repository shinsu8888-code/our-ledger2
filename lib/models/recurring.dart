import 'dart:convert';

/// 정기입출금 (매달 자동 입력: 월급, 월세, 통신비 등)
class RecurringEntry {
  final String id;
  final bool isIncome;
  final String category;
  final int amount;
  final String note;
  final int dayOfMonth; // 매달 몇 일에 기록할지
  String lastApplied; // 마지막 자동입력 월 ('yyyy-MM')

  RecurringEntry({
    required this.id,
    required this.isIncome,
    required this.category,
    required this.amount,
    required this.note,
    required this.dayOfMonth,
    this.lastApplied = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isIncome': isIncome,
        'category': category,
        'amount': amount,
        'note': note,
        'dayOfMonth': dayOfMonth,
        'lastApplied': lastApplied,
      };

  factory RecurringEntry.fromJson(Map<dynamic, dynamic> j) => RecurringEntry(
        id: (j['id'] as String?) ?? '',
        isIncome: (j['isIncome'] as bool?) ?? false,
        category: (j['category'] as String?) ?? '기타 지출',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        note: (j['note'] as String?) ?? '',
        dayOfMonth: (j['dayOfMonth'] as num?)?.toInt() ?? 1,
        lastApplied: (j['lastApplied'] as String?) ?? '',
      );
}

/// 자동 분류 규칙: 메모에 이 키워드가 있으면 이 카테고리로 추천
class CaptureRule {
  final String keyword;
  final String category;

  CaptureRule({required this.keyword, required this.category});

  Map<String, dynamic> toJson() => {'keyword': keyword, 'category': category};

  factory CaptureRule.fromJson(Map<dynamic, dynamic> j) => CaptureRule(
        keyword: (j['keyword'] as String?) ?? '',
        category: (j['category'] as String?) ?? '기타 지출',
      );
}

/// 자동입력 대기 항목 (카드/뱅킹 알림에서 파싱)
class PendingCapture {
  final String id;
  final bool isIncome;
  final int amount;
  final String bank;
  final String note;
  final int ts; // milliseconds

  PendingCapture({
    required this.id,
    required this.isIncome,
    required this.amount,
    required this.bank,
    required this.note,
    required this.ts,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isIncome': isIncome,
        'amount': amount,
        'bank': bank,
        'note': note,
        'ts': ts,
      };

  factory PendingCapture.fromJson(Map<dynamic, dynamic> j) => PendingCapture(
        id: (j['id'] as String?) ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        isIncome: (j['isIncome'] as bool?) ?? false,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        bank: (j['bank'] as String?) ?? '',
        note: (j['note'] as String?) ?? '',
        ts: (j['ts'] as num?)?.toInt() ?? 0,
      );

  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}

String encodeList(List<dynamic> items) => jsonEncode(items);
