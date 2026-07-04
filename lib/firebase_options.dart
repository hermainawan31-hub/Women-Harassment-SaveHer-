import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;

      default:
        throw UnsupportedError(
          'Firebase is not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBZpfH1izbnKzbNm_w01NwLldrtYxbWCD4',
    appId: '1:805087173127:web:81299e09f2e6dc69a068a2',
    messagingSenderId: '805087173127',
    projectId: 'safeher-dd07d',
    authDomain: 'safeher-dd07d.firebaseapp.com',
    storageBucket: 'safeher-dd07d.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDyBAiCiUPn1MnYE53DJh7sgMOhqi6I5aI',
    appId: '1:805087173127:android:2413c76e67509515a068a2',
    messagingSenderId: '805087173127',
    projectId: 'safeher-dd07d',
    storageBucket: 'safeher-dd07d.firebasestorage.app',
  );
}