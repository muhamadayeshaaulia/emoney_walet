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
    apiKey: 'AIzaSyCurlZkPJHmEhfAHXGEYBZt6DZLsWFqRLs', // Web API key might differ, but we put Android's for now
    appId: '1:597810091743:web:dummy', 
    messagingSenderId: '597810091743',
    projectId: 'e-money-eceef',
    authDomain: 'e-money-eceef.firebaseapp.com',
    storageBucket: 'e-money-eceef.firebasestorage.app',
    measurementId: 'G-DUMMY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCurlZkPJHmEhfAHXGEYBZt6DZLsWFqRLs',
    appId: '1:597810091743:android:936cf58bfa68e228ab3b6a',
    messagingSenderId: '597810091743',
    projectId: 'e-money-eceef',
    storageBucket: 'e-money-eceef.firebasestorage.app',
  );
}
