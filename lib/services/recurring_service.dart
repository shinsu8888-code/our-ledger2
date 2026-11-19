import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

import '../services/prefs_service.dart';

/// 정기입출금 자동 반영 + 로컬 알림
///
/// - 앱을 켤 때마다 "매달 n일" 정기입출금 중 이번 달에 아직 안 반영된 것을
///   자동으로 거래 기록에 추가한다.
/// - 앱 알림(월급날 리마인드 등)은 앱이 실행 중일 때 표시된다.
class RecurringService {
  /// 이번 달분 중 미반영 정기입출금을 모두 반영 → 반영한 개수 반환
  static Future<int> applyAll({
    required String householdId,
    required String ownerUid,
    required Future<void> Function(bool isIncome, String category, int amount, String note)
        addTx,
  }) async {
    final now = DateTime.now();
    final key = DateFormat('yyyy-MM').format(now);
    var applied = 0;

    final list = Prefs.recurrings;
    for (final r in list) {
      if (r.lastApplied == key) continue; // 이번 달 이미 반영
      if (now.day < r.dayOfMonth) continue; // 아직 날짜 안 됨
      await addTx(r.isIncome, r.category, r.amount,
          r.note.isEmpty ? '정기입출금' : r.note);
      r.lastApplied = key;
      applied++;
    }
    if (applied > 0) Prefs.setRecurrings(list);
    return applied;
  }

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// 알림 권한 요청 (Android 13+)
  static Future<void> requestPermission() async {
    await _init();
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> show(String title, String body) async {
    await _init();
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'recurring_channel',
          '정기입출금 · 리마인드',
          channelDescription: '월급날 알림, 예산 초과 경고 등',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
