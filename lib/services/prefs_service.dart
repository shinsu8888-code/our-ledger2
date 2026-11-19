import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recurring.dart';

/// 기기에 저장되는 설정 (예산, PIN, 다크모드, 정기입출금, 규칙, 자동입력 대기)
class Prefs {
  static late SharedPreferences _p;
  static Future<void> init() async {
    _p = await SharedPreferences.getInstance();
  }

  // ---- 일반 문자열 저장 (로컬 거래 목록 등) ----
  static String? rawString(String key) => _p.getString(key);
  static Future<void> setRawString(String key, String value) =>
      _p.setString(key, value);

  // ---- 시작 잔액(이월 잔액) ----
  static int get startBalance => _p.getInt('startBalance') ?? 0;
  static set startBalance(int v) => _p.setInt('startBalance', v);

  // ---- 오프라인 모드 내 프로필 ----
  static String get localName => _p.getString('localName') ?? '나';
  static set localName(String v) => _p.setString('localName', v);
  static int get localSalary => _p.getInt('localSalary') ?? 0;
  static set localSalary(int v) => _p.setInt('localSalary', v);

  // ---- 잠금 PIN ----
  static String get pin => _p.getString('pin') ?? '';
  static set pin(String v) =>
      v.isEmpty ? _p.remove('pin') : _p.setString('pin', v);

  // ---- 다크 모드 ----
  static bool get darkMode => _p.getBool('darkMode') ?? false;
  static set darkMode(bool v) => _p.setBool('darkMode', v);

  // ---- 카테고리별 월 예산 ----
  static Map<String, int> get budgets {
    final raw = _p.getString('budgets');
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map);
    return m.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
  }

  static void setBudget(String category, int amount) {
    final b = budgets;
    if (amount <= 0) {
      b.remove(category);
    } else {
      b[category] = amount;
    }
    _p.setString('budgets', jsonEncode(b));
  }

  // ---- 정기입출금 ----
  static List<RecurringEntry> get recurrings {
    final raw = _p.getString('recurrings');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => RecurringEntry.fromJson(e as Map))
        .toList();
  }

  static void setRecurrings(List<RecurringEntry> list) => _p.setString(
      'recurrings', jsonEncode(list.map((e) => e.toJson()).toList()));

  // ---- 자동 분류 규칙 (메모 키워드 -> 카테고리) ----
  static List<CaptureRule> get rules {
    final raw = _p.getString('rules');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => CaptureRule.fromJson(e as Map))
        .toList();
  }

  static void setRules(List<CaptureRule> list) =>
      _p.setString('rules', jsonEncode(list.map((e) => e.toJson()).toList()));

  /// 메모로 카테고리 추천
  static String suggestCategory(String note, {required bool isIncome}) {
    final n = note.toLowerCase();
    for (final r in rules) {
      if (n.contains(r.keyword.toLowerCase())) return r.category;
    }
    return isIncome ? '기타 수입' : '기타 지출';
  }

  // ---- 자동입력 대기 목록 ----
  static List<PendingCapture> get pending {
    final raw = _p.getString('pending');
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => PendingCapture.fromJson(e as Map))
        .toList();
  }

  static void setPending(List<PendingCapture> list) =>
      _p.setString('pending', jsonEncode(list.map((e) => e.toJson()).toList()));
}
