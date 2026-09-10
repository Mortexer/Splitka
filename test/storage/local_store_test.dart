import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cloud room IDs remain case-sensitive in the local cache', () async {
    SharedPreferences.setMockInitialValues({});
    final store = LocalStore();
    await store.saveHousehold(createDefaultHousehold('ABC'), revision: 4);
    await store.saveHousehold(createDefaultHousehold('abc'), revision: 2);
    expect((await store.loadHouseholdSnapshot('ABC')).revision, 4);
    expect((await store.loadHouseholdSnapshot('abc')).revision, 2);
  });
}
