import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class SplitkaFirebaseConfig {
  const SplitkaFirebaseConfig._();

  static const projectId = 'splitka-18560';
  static const enabled = !bool.fromEnvironment('SPLITKA_LOCAL_ONLY');

  static bool get isConfigured =>
      enabled && !kIsWeb && optionsForPlatform(defaultTargetPlatform) != null;

  static FirebaseOptions get options {
    return optionsForPlatform(defaultTargetPlatform) ??
        (throw UnsupportedError('Splitka supports Android and iOS.'));
  }

  static FirebaseOptions? optionsForPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  // Public client configuration; access is controlled by Firestore rules.
  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBSY7dLeuceWalGLJ50BYPY6ZIBrQpjqj0',
    appId: '1:468039135218:android:658ee42a1a5093a1e8056b',
    messagingSenderId: '468039135218',
    projectId: projectId,
    storageBucket: 'splitka-18560.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyC4g-otV9m0CHXA2rqSSufzvwIbnFVbyeI',
    appId: '1:468039135218:ios:e1ab248e1d67c65be8056b',
    messagingSenderId: '468039135218',
    projectId: projectId,
    storageBucket: 'splitka-18560.firebasestorage.app',
    iosBundleId: 'pl.splitka.splitkaFlutter',
  );
}
