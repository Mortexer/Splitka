import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitka_flutter/main.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/state/household_controller.dart';
import 'package:splitka_flutter/ui/common_widgets.dart';
import 'package:splitka_flutter/ui/receipt_detail_screen.dart';
import 'package:splitka_flutter/ui/room_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on the Splitka dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SplitkaApp());
    await tester.pumpAndSettle();

    expect(find.text('Splitka'), findsOneWidget);
    expect(find.text('Importuj JSON'), findsOneWidget);
    expect(find.text('Brak paragonów'), findsOneWidget);
    expect(find.text('Rachunki'), findsOneWidget);
    expect(find.text('Listy zakupów'), findsOneWidget);
  });

  testWidgets('keeps a shared shopping list and separate member lists', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SplitkaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listy zakupów'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(ChoiceChip, 'Wspólna'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Danuś'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Kubuś'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('shopping-list-selector')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Damian'), findsOneWidget);
    await tester.drag(
      find.byKey(const ValueKey('shopping-list-selector')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('shopping-input-common')),
      'Mleko',
    );
    await tester.tap(find.byTooltip('Dodaj do listy'));
    await tester.pumpAndSettle();
    expect(find.text('Mleko'), findsOneWidget);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(find.text('Usuń kupione (1)'), findsOneWidget);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Kubuś'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Kubuś'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('shopping-input-kubus')),
      'Kawa',
    );
    await tester.tap(find.byTooltip('Dodaj do listy'));
    await tester.pumpAndSettle();
    expect(find.text('Kawa'), findsOneWidget);
    expect(find.text('Mleko'), findsNothing);

    await tester.drag(
      find.byKey(const ValueKey('shopping-list-selector')),
      const Offset(600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Wspólna'));
    await tester.pumpAndSettle();
    expect(find.text('Mleko'), findsOneWidget);
    await tester.tap(find.text('Usuń kupione (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Lista jest pusta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a receipt, handles Android back and confirms deletion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const SplitkaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dodaj ręcznie'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Testowy rachunek');
    await tester.ensureVisible(find.text('Utwórz'));
    await tester.tap(find.text('Utwórz'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptDetailScreen), findsNothing);
    await tester.tap(
      find.textContaining('Testowy rachunek', findRichText: true),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_rounded).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptDetailScreen), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usun'));
    await tester.pumpAndSettle();
    expect(find.text('Brak paragonów'), findsOneWidget);
    expect(find.text('Paragon usuniety.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed product save keeps the entered values', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: AddItemForm(
              members: defaultMembers,
              onAddItem: (_, _) async => false,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(0), 'Chleb');
    await tester.enterText(find.byType(TextField).at(1), '12,50');
    await tester.ensureVisible(find.text('Dodaj'));
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();
    expect(find.text('Chleb'), findsOneWidget);
    expect(find.text('12,50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 700), const Size(390, 844)]) {
    testWidgets(
      'invitation dialog fits $size and shows invalid code feedback',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final controller = HouseholdController();
        addTearDown(controller.dispose);
        await controller.boot();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(),
            home: Scaffold(body: RoomDialog(controller: controller)),
          ),
        );
        await tester.enterText(find.byType(TextField), 'stancja');
        await tester.tap(find.text('Dołącz do mieszkania'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Wklej pełny kod'), findsOneWidget);
        expect(controller.isCloudRoom, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
