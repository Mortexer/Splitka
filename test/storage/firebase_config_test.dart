import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitka_flutter/storage/firebase_config.dart';

void main() {
  test('selects distinct registered apps in the same Firebase project', () {
    final android = SplitkaFirebaseConfig.optionsForPlatform(
      TargetPlatform.android,
    )!;
    final ios = SplitkaFirebaseConfig.optionsForPlatform(TargetPlatform.iOS)!;

    expect(android.projectId, 'splitka-18560');
    expect(ios.projectId, android.projectId);
    expect(android.appId, contains(':android:'));
    expect(ios.appId, contains(':ios:'));
    expect(ios.iosBundleId, 'pl.splitka.splitkaFlutter');
    expect(android.apiKey, isNot(ios.apiKey));
  });

  test('does not use mobile credentials on another platform', () {
    for (final platform in [
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.macOS,
    ]) {
      expect(SplitkaFirebaseConfig.optionsForPlatform(platform), isNull);
    }
  });

  test('uses a dedicated web app in the same Firebase project', () {
    expect(SplitkaFirebaseConfig.web.projectId, 'splitka-18560');
    expect(SplitkaFirebaseConfig.web.appId, contains(':web:'));
    expect(
      SplitkaFirebaseConfig.web.authDomain,
      'splitka-18560.firebaseapp.com',
    );
  });
}
