import 'package:firebase_core/firebase_core.dart';

class SplitkaFirebaseConfig {
  const SplitkaFirebaseConfig._();

  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: String.fromEnvironment('EXPO_PUBLIC_FIREBASE_API_KEY'),
  );
  static const authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: String.fromEnvironment('EXPO_PUBLIC_FIREBASE_AUTH_DOMAIN'),
  );
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: String.fromEnvironment('EXPO_PUBLIC_FIREBASE_PROJECT_ID'),
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: String.fromEnvironment('EXPO_PUBLIC_FIREBASE_STORAGE_BUCKET'),
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: String.fromEnvironment(
      'EXPO_PUBLIC_FIREBASE_MESSAGING_SENDER_ID',
    ),
  );
  static const appId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: String.fromEnvironment('EXPO_PUBLIC_FIREBASE_APP_ID'),
  );

  static bool get isConfigured {
    return apiKey.isNotEmpty &&
        projectId.isNotEmpty &&
        appId.isNotEmpty &&
        messagingSenderId.isNotEmpty;
  }

  static FirebaseOptions get options {
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain,
      storageBucket: storageBucket,
    );
  }
}
