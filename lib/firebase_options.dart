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
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAhypeqhZM_vXGBHM5CJo-Kq2uJAfdqRo4',
    appId: '1:205631437885:web:8aaf31cf21bd5ee2c0fe54',
    messagingSenderId: '205631437885',
    projectId: 'myapplication-8823f133',
    authDomain: 'myapplication-8823f133.firebaseapp.com',
    storageBucket: 'myapplication-8823f133.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyAndroidPlaceholder',
    appId: '1:123456789:android:1234567890abcdef',
    messagingSenderId: '123456789',
    projectId: 'artist-community-app',
    storageBucket: 'artist-community-app.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyIOSPlaceholder',
    appId: '1:123456789:ios:1234567890abcdef',
    messagingSenderId: '123456789',
    projectId: 'artist-community-app',
    storageBucket: 'artist-community-app.appspot.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyMacPlaceholder',
    appId: '1:123456789:macos:1234567890abcdef',
    messagingSenderId: '123456789',
    projectId: 'artist-community-app',
    storageBucket: 'artist-community-app.appspot.com',
  );
}