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
    apiKey: 'AIzaSyDBBesTejBkImWY0TfR5r3g1VYERT3RPMc',
    appId: '1:597810091743:web:34d383d9cc0702dcab3b6a',
    messagingSenderId: '597810091743',
    projectId: 'e-money-eceef',
    authDomain: 'e-money-eceef.firebaseapp.com',
    storageBucket: 'e-money-eceef.firebasestorage.app',
    measurementId: 'G-9DZYJTQDM6',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCurlZkPJHmEhfAHXGEYBZt6DZLsWFqRLs',
    appId: '1:597810091743:android:79a533fbbb8fd3bdab3b6a',
    messagingSenderId: '597810091743',
    projectId: 'e-money-eceef',
    storageBucket: 'e-money-eceef.firebasestorage.app',
  );

}