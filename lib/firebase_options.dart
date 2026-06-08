import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAO83rJb5F_ginjTktQO-wxhcHLtNZYXLM',
    appId: '1:356293982231:web:557bceaa0728cf0e73c452',
    messagingSenderId: '356293982231',
    projectId: 'projectlanjutan-7cdac',
    authDomain: 'projectlanjutan-7cdac.firebaseapp.com',
    storageBucket: 'projectlanjutan-7cdac.firebasestorage.app',
    measurementId: 'G-E2JTXL8J57',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5vF4nLEbktOme_LdYsMfuSeLvAEhW5Rk',
    appId: '1:356293982231:android:16ff0cba671b1ced73c452',
    messagingSenderId: '356293982231',
    projectId: 'projectlanjutan-7cdac',
    storageBucket: 'projectlanjutan-7cdac.firebasestorage.app',
  );
}
