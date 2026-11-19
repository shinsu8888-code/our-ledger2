import 'dart:async';

import 'package:flutter_notification_listener/flutter_notification_listener.dart';

import '../models/recurring.dart';
import 'prefs_service.dart';

/// 카드사/은행 알림(문자·앱 푸시)을 읽어 "자동입력 대기 목록"에 담는 서비스.
///
/// 뱅크샐러드 같은 은행 스크래핑(마이데이터)은 금융위 라이선스가 필요해
/// 개인 앱은 불가능하므로, 폰에 오는 결제·출금·입금 알림을
/// 기기 안에서만 읽어 금액을 자동으로 채워준다. (서버로 나가는 데이터 없음)
class AutoCapture {
  static StreamSubscription? _sub;
  static void Function()? onChanged; // 새 대기 항목 생기면 호출

  static const _bankKeywords = [
    '신한', '삼성카드', 'KB국민', '국민카드', 'KB카드', '우리', '하나', '롯데카드',
    '현대카드', '농협', 'NH', '카카오뱅크', '카카오페이', '토스', '아이엠뱅크', 'IM뱅크',
    '대구은행', '부산은행', '수협', '새마을금고', '제주은행', '기업은행', 'SC제일',
    '씨티', '광주은행', '전북은행', '쿠팡', '네이버페이', '신협', '우체국',
  ];

  /// 콜백 핸들 등록용 top-level/static 함수
  static void _noop(NotificationEvent e) {}

  static Future<void> init() async {
    try {
      await NotificationsListener.initialize(callbackHandle: _noop);
      _sub?.cancel();
      _sub = NotificationsListener.receivePort?.listen((evt) {
        try {
          final e = NotificationEvent.fromMap(evt as Map);
          _handle(e);
        } catch (_) {}
      });
      await NotificationsListener.startService();
    } catch (_) {
      // 권한이 아직 없으면 조용히 넘어감 (설정 탭에서 권한 요청 가능)
    }
  }

  static Future<void> openPermissionSettings() async {
    try {
      await NotificationsListener.openPermissionSettings();
    } catch (_) {}
  }

  static void _handle(NotificationEvent e) {
    final pkg = (e.packageName ?? '').toLowerCase();
    // 문자 앱 + 은행/카드/결제 관련 앱의 알림만
    final financial = pkg.contains('sms') ||
        pkg.contains('mms') ||
        pkg.contains('msg') ||
        pkg.contains('bank') ||
        pkg.contains('card') ||
        pkg.contains('pay') ||
        pkg.contains('finance') ||
        pkg.contains('toss') ||
        pkg.contains('kbstar') ||
        pkg.contains('shinhan') ||
        pkg.contains('samsung') ||
        pkg.contains('wooribank') ||
        pkg.contains('kebhana');
    if (!financial) return;

    final text =
        '${e.title ?? ''} ${e.text ?? ''}'.replaceAll(RegExp(r'\s+'), ' ');
    if (text.trim().isEmpty) return;

    final parsed = parseCapture(text);
    if (parsed == null) return;

    final list = Prefs.pending;
    // 중복 방지 (같은 금액+메모가 이미 대기 중이면 스킵)
    if (list.any((p) => p.amount == parsed.amount && p.note == parsed.note)) {
      return;
    }
    list.insert(0, parsed);
    if (list.length > 50) list.removeLast();
    Prefs.setPending(list);
    onChanged?.call();
  }

  /// 한국 카드사/은행 알림문 파싱
  static PendingCapture? parseCapture(String raw) {
    final t = raw.replaceAll(RegExp(r'\s+'), ' ');
    final isExpense =
        RegExp(r'(승인|사용|지출|출금|체크|신용|결제|해피거래|자동이체|구매)').hasMatch(t);
    final isIncome = RegExp(r'(입금|급여|이자|송금)').hasMatch(t);
    if (!isExpense && !isIncome) return null;

    int amount = 0;
    for (final m in RegExp(r'([\d,]{3,})\s*원').allMatches(t)) {
      final v = int.tryParse(m.group(1)!.replaceAll(',', ''));
      if (v != null && v >= 10) {
        amount = v;
        break;
      }
    }
    if (amount == 0) return null;

    String bank = '';
    for (final b in _bankKeywords) {
      if (t.contains(b)) {
        bank = b;
        break;
      }
    }

    final note = bank.isEmpty ? t.trim() : '$bank $t'.trim();
    return PendingCapture(
      id: PendingCapture.newId(),
      isIncome: isIncome,
      amount: amount,
      bank: bank,
      note: note.length > 60 ? note.substring(0, 60) : note,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
  }
}
