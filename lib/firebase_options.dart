import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: dotenv.env['SENTINEL_FIREBASE_API_KEY_WEB'] ?? '',
    appId: dotenv.env['SENTINEL_FIREBASE_APP_ID_WEB'] ?? '',
    messagingSenderId: dotenv.env['SENTINEL_FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['SENTINEL_FIREBASE_PROJECT_ID'] ?? '',
    authDomain: dotenv.env['SENTINEL_FIREBASE_AUTH_DOMAIN'] ?? '',
    storageBucket: dotenv.env['SENTINEL_FIREBASE_STORAGE_BUCKET'] ?? '',
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: dotenv.env['SENTINEL_FIREBASE_API_KEY_ANDROID'] ?? '',
    appId: dotenv.env['SENTINEL_FIREBASE_APP_ID_ANDROID'] ?? '',
    messagingSenderId: dotenv.env['SENTINEL_FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['SENTINEL_FIREBASE_PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['SENTINEL_FIREBASE_STORAGE_BUCKET'] ?? '',
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: dotenv.env['SENTINEL_FIREBASE_API_KEY_IOS'] ?? '',
    appId: dotenv.env['SENTINEL_FIREBASE_APP_ID_IOS'] ?? '',
    messagingSenderId: dotenv.env['SENTINEL_FIREBASE_MESSAGING_SENDER_ID'] ?? '',
    projectId: dotenv.env['SENTINEL_FIREBASE_PROJECT_ID'] ?? '',
    storageBucket: dotenv.env['SENTINEL_FIREBASE_STORAGE_BUCKET'] ?? '',
    iosBundleId: 'com.example.vasihatNama',
  );

  static FirebaseOptions get macos => ios;

  static FirebaseOptions get windows => web;
}