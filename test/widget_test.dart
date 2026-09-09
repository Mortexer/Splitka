import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitka_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on the Splitka dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SplitkaApp());
    await tester.pumpAndSettle();

    expect(find.text('Splitka'), findsOneWidget);
    expect(find.text('Importuj JSON'), findsOneWidget);
    expect(find.text('Brak paragonów'), findsOneWidget);
  });
}
