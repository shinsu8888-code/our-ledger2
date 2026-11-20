// ============================================================
//  Firebase 연결 설정 (ourledger-c9548 프로젝트)
//  android 블록에 실제 값이 들어있으므로 앱이 "부부 동기화 모드"로 실행됩니다.
//  로그인/데이터 동기화에 ios·web 블록은 사용하지 않습니다.
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
          '이 플랫폼은 지원하지 않습니다.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAq8WTskcvdil6JCWWfzMy8S58oZBwSE9w',
    appId: '1:359026297598:android:f2a40977f03f130e3bb3af',
    messagingSenderId: '359026297598',
    projectId: 'ourledger-c9548',
    storageBucket: 'ourledger-c9548.firebasestorage.app',
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
