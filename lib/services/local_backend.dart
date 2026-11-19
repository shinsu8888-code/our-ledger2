import 'dart:async';
import 'dart:convert';

import '../models/household.dart';
import '../models/transaction_entry.dart';
import 'prefs_service.dart';

/// 오프라인(내 폰 전용) 모드의 로컬 저장소
/// Firebase 설정 전에도 가계부 전체 기능을 쓸 수 있게 해준다.
class LocalStore {
  LocalStore._();
  static final LocalStore instance = LocalStore._();

  static const String localUid = 'local';
  static const _key = 'localTxs';

  final _ctrl = StreamController<List<TxEntry>>.broadcast();
  List<TxEntry> _txs = [];
  bool _loaded = false;

  void _ensureLoaded() {
    if (_loaded) return;
    _loaded = true;
    try {
      final json = Prefs.rawString(_key);
      if (json != null && json.isNotEmpty) {
        _txs = (jsonDecode(json) as List)
            .map((e) => _fromLocalJson(e as Map))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
      }
    } catch (_) {}
  }

  static TxEntry _fromLocalJson(Map j) => TxEntry(
        id: (j['id'] as String?) ?? '',
        type: (j['type'] as String?) == 'income' ? TxType.income : TxType.expense,
        category: (j['category'] as String?) ?? '기타 지출',
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        note: (j['note'] as String?) ?? '',
        date: DateTime.tryParse((j['date'] as String?) ?? '') ?? DateTime.now(),
        ownerUid: localUid,
        createdAt: DateTime.tryParse((j['createdAt'] as String?) ?? '') ??
            DateTime.now(),
      );

  static Map<String, dynamic> _toLocalJson(TxEntry t) => {
        'id': t.id,
        'type': t.isIncome ? 'income' : 'expense',
        'category': t.category,
        'amount': t.amount,
        'note': t.note,
        'date': t.date.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
      };

  List<TxEntry> get current {
    _ensureLoaded();
    return List.unmodifiable(_txs);
  }

  Stream<List<TxEntry>> stream() {
    _ensureLoaded();
    // 구독 즉시 현재 목록 전달
    Future.microtask(() {
      if (!_ctrl.isClosed) _ctrl.add(current);
    });
    return _ctrl.stream;
  }

  Future<void> add(TxEntry e) async {
    _ensureLoaded();
    _txs.add(e);
    _txs.sort((a, b) => b.date.compareTo(a.date));
    await _save();
  }

  Future<void> delete(String id) async {
    _ensureLoaded();
    _txs.removeWhere((t) => t.id == id);
    await _save();
  }

  Future<void> _save() async {
    await Prefs.setRawString(
        _key, jsonEncode(_txs.map(_toLocalJson).toList()));
    if (!_ctrl.isClosed) _ctrl.add(current);
  }

  /// 오프라인 모드의 가계부(프로필: 이름/월급은 설정에서 수정)
  Household household() => Household(
        id: 'local',
        name: '나의 가계부',
        inviteCode: '',
        members: [localUid],
        profiles: {
          localUid: MemberProfile(
              name: Prefs.localName, monthlySalary: Prefs.localSalary),
        },
      );
}
