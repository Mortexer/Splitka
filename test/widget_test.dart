import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitka_flutter/main.dart';
import 'package:splitka_flutter/domain/models.dart';
import 'package:splitka_flutter/domain/settlements.dart';
import 'package:splitka_flutter/state/household_controller.dart';
import 'package:splitka_flutter/ui/common_widgets.dart';
import 'package:splitka_flutter/ui/group_settings_screen.dart';
import 'package:splitka_flutter/ui/receipt_detail_screen.dart';
import 'package:splitka_flutter/ui/room_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('starts on the Splitka dashboard', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SplitkaApp());
    await tester.pumpAndSettle();

    expect(find.text('Splitka'), findsOneWidget);
    expect(find.text('Importuj paragon (JSON)'), findsOneWidget);
    expect(find.text('Brak paragonów'), findsOneWidget);
    expect(find.text('Rozliczenia'), findsOneWidget);
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
    await tester.drag(
      find.byKey(const ValueKey('shopping-list-selector')),
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Kubuś'), findsOneWidget);
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

    await tester.tap(find.byTooltip('Oznacz jako kupione'));
    await tester.pumpAndSettle();
    expect(find.text('Usuń kupione (1)'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('shopping-list-selector')),
      const Offset(-160, 0),
    );
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
    expect(find.text('Pusta lista'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates a receipt, handles Android back and confirms deletion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
    expect(
      tester.getTopLeft(find.text('Rozliczenie')).dy,
      lessThan(
        tester
            .getTopLeft(
              find.textContaining('Testowy rachunek', findRichText: true),
            )
            .dy,
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.textContaining('Testowy rachunek', findRichText: true),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('receipt-actions')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Usuń paragon'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(find.byType(ReceiptDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('receipt-actions')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usuń paragon'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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

  testWidgets('participant controls support a larger group on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final members = List.generate(
      8,
      (index) => Person(
        id: 'member-$index',
        name: 'Osoba ${index + 1}',
        color: 0xFF45B164 + index * 0x00030705,
      ),
    );
    final household = Household(
      id: 'trip',
      members: members,
      receipts: const [],
      updatedAt: 1,
    );
    var selectedPayerId = members.first.id;
    var selectedIds = members.map((person) => person.id).toList();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                PersonSelector(
                  members: members,
                  selectedId: members.first.id,
                  onSelected: (personId) => selectedPayerId = personId,
                ),
                const SizedBox(height: 12),
                ParticipantMultiSelector(
                  members: members,
                  selectedIds: selectedIds,
                  onChanged: (next) => selectedIds = next,
                ),
                const SizedBox(height: 12),
                SettlementCard(
                  settlement: calculateSettlement(household),
                  members: members,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Osoba 1'), findsWidgets);
    expect(find.byKey(const ValueKey('single-person-picker')), findsOneWidget);
    expect(find.byKey(const ValueKey('multi-person-picker')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('single-person-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('picker-person-member-3')));
    await tester.pumpAndSettle();
    expect(selectedPayerId, 'member-3');

    await tester.tap(find.byKey(const ValueKey('multi-person-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('picker-person-member-0')));
    await tester.tap(find.text('Zastosuj'));
    await tester.pumpAndSettle();
    expect(selectedIds, hasLength(7));
    expect(selectedIds, isNot(contains('member-0')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('manages group name and participants on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SplitkaApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-group-settings')));
    await tester.pumpAndSettle();

    expect(find.byType(GroupSettingsScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('edit-group-name')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('group-name-input')),
      'Wyjazd w góry',
    );
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(find.text('Wyjazd w góry'), findsOneWidget);

    await tester.ensureVisible(find.text('Dodaj osobę'));
    await tester.tap(find.text('Dodaj osobę'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('member-name-input')),
      'Ola',
    );
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(find.text('Ola'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates and switches between groups on a small screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final controller = HouseholdController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(SplitkaApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-group-switcher')));
    await tester.pumpAndSettle();
    expect(find.text('Twoje grupy'), findsOneWidget);

    await tester.tap(find.text('Nowa grupa'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('new-group-name')),
      'Wyjazd',
    );
    await tester.pump();
    await tester.tap(find.text('Utwórz'));
    await tester.pumpAndSettle();
    expect(controller.error, isNull);
    expect(controller.household.name, 'Wyjazd');
    expect(find.text('WYJAZD'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('open-group-switcher')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stancja'));
    await tester.pumpAndSettle();
    expect(find.text('STANCJA'), findsOneWidget);
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
        await tester.tap(find.text('Dołącz do grupy'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Wpisz 4-cyfrowy kod'), findsOneWidget);
        expect(controller.isCloudRoom, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
