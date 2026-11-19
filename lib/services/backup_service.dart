import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/household.dart';
import '../models/transaction_entry.dart';
import 'household_service.dart';

/// 백업 / 내보내기 / 가져오기
class BackupService {
  /// CSV 내보내기 후 공유 시트 열기 (엑셀에서 바로 열림)
  static Future<void> exportCsv(
      BuildContext context, List<TxEntry> txs, Household household) async {
    final rows = <List<dynamic>>[
      ['날짜', '구분', '카테고리', '금액', '메모', '작성자'],
    ];
    for (final t in txs) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(t.date),
        t.isIncome ? '수입' : '지출',
        t.category,
        t.amount,
        t.note,
        household.profileOf(t.ownerUid).name,
      ]);
    }
    final csvText = const CsvEncoder().convert(rows);
    final dir = await getTemporaryDirectory();
    final f = File(
        '${dir.path}/가계부_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv');
    // 엑셀 한글 호환을 위해 BOM 추가
    await f.writeAsBytes(utf8.encoder.convert(csvText), flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
  }

  /// CSV 가져오기 (엑셀에서 '다른 이름으로 저장 → CSV'로 저장한 파일)
  /// 컬럼 순서: 날짜,구분,카테고리,금액,메모
  static Future<int> importCsv({
    required String householdId,
    required String ownerUid,
  }) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (picked.isEmpty || picked.single.path == null) return 0;
    final content =
        await File(picked.single.path!).readAsString(encoding: utf8);
    final table = const CsvDecoder().convert(content);

    var count = 0;
    final repo = TxRepository(householdId);
    for (final row in table.skip(1)) {
      if (row.length < 4) continue;
      try {
        final date = DateFormat('yyyy-MM-dd').parse(row[0].toString().trim());
        final isIncome = row[1].toString().contains('수입');
        final amount =
            int.tryParse(row[3].toString().replaceAll(RegExp(r'[^0-9]'), ''));
        if (amount == null || amount <= 0) continue;
        await repo.add(TxEntry(
          id: '',
          type: isIncome ? TxType.income : TxType.expense,
          category: row[2].toString().trim(),
          amount: amount,
          note: row.length > 4 ? row[4].toString().trim() : '',
          date: date,
          ownerUid: ownerUid,
          createdAt: DateTime.now(),
        ));
        count++;
      } catch (_) {
        // 형식이 안 맞는 줄은 건너뜀
      }
    }
    return count;
  }

  /// 전체 백업(JSON) 텍스트 만들기
  static String exportJson(
      List<TxEntry> txs, Household household, int startBalance) {
    return jsonEncode({
      'app': 'couple_ledger',
      'version': 2,
      'household': household.name,
      'startBalance': startBalance,
      'transactions': [
        for (final t in txs)
          {
            'type': t.isIncome ? 'income' : 'expense',
            'category': t.category,
            'amount': t.amount,
            'note': t.note,
            'date': DateFormat('yyyy-MM-dd').format(t.date),
            'owner': household.profileOf(t.ownerUid).name,
          },
      ],
    });
  }

  /// 백업 파일(JSON) 공유
  static Future<void> shareJson(BuildContext context, String jsonText) async {
    final dir = await getTemporaryDirectory();
    final f = File(
        '${dir.path}/가계부_백업_${DateFormat('yyyyMMdd').format(DateTime.now())}.json');
    await f.writeAsString(jsonText, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)]));
  }

  /// 백업 JSON 파일 고르기
  static Future<List<Map<String, dynamic>>> pickBackupJson() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (picked.isEmpty || picked.single.path == null) return [];
    final content =
        await File(picked.single.path!).readAsString(encoding: utf8);
    final data = jsonDecode(content) as Map<String, dynamic>;
    return ((data['transactions'] as List?) ?? [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  /// 백업 JSON 내용을 내 거래로 복원 → 복원한 개수 반환
  static Future<int> restoreJson({
    required String householdId,
    required String ownerUid,
  }) async {
    final list = await pickBackupJson();
    var count = 0;
    final repo = TxRepository(householdId);
    for (final t in list) {
      try {
        final amount = (t['amount'] as num?)?.toInt();
        if (amount == null || amount <= 0) continue;
        await repo.add(TxEntry(
          id: '',
          type: t['type'] == 'income' ? TxType.income : TxType.expense,
          category: (t['category'] as String?) ?? '기타 지출',
          amount: amount,
          note: (t['note'] as String?) ?? '',
          date: DateFormat('yyyy-MM-dd').parse((t['date'] as String?) ??
              DateFormat('yyyy-MM-dd').format(DateTime.now())),
          ownerUid: ownerUid,
          createdAt: DateTime.now(),
        ));
        count++;
      } catch (_) {}
    }
    return count;
  }
}
