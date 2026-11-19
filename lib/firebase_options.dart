// ============================================================
//  이 파일은 "템플릿"입니다.
//  부부 동기화 모드를 켜려면 Firebase 콘솔의 여러분 프로젝트 값으로
//  아래 REPLACE~ 부분을 교체하면 됩니다 (지금은 그대로 두어도 됩니다).
//  빈칸(템플릿) 상태에서 빌드하면 앱이 "오프라인 모드(내 폰 전용)"로 실행됩니다.
// ============================================================
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          '이 플랫폼은 템플릿에서 지원하지 않습니다. Firebase 설정값을 넣어주세요.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyREPLACE-WITH-YOUR-KEY',
    appId: '1:000000000000:android:replace00000000000000',
    messagingSenderId: '000000000000',
    projectId: 'replace-me',
    storageBucket: 'replace-me.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyREPLACE-WITH-YOUR-KEY',
    appId: '1:000000000000:ios:replace00000000000000',
    messagingSenderId: '000000000000',
    projectId: 'replace-me',
    storageBucket: 'replace-me.appspot.com',
    iosBundleId: 'com.example.coupleLedger',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyREPLACE-WITH-YOUR-KEY',
    appId: '1:000000000000:web:replace00000000000000',
    messagingSenderId: '000000000000',
    projectId: 'replace-me',
  );
}
