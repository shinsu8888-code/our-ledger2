/// 앱 동작 모드
/// - cloud  : Firebase 설정 완료 → 로그인 + 부부 실시간 동기화
/// - offline: 설정 전 → 내 폰 전용 가계부 (기록·보고서·예산 등 전부 사용 가능)
class AppMode {
  static bool cloud = false;
}
