# Splitka

Mobilna apka Flutter do dzielenia rachunkow miedzy wspollokatorow.

Domyslny pokoj: `stancja`

Domyslne osoby:

- Danus
- Kubus
- Damian

## Co juz robi

- importuje JSON z paragonu Biedronki,
- pozwala dodawac rachunki i pozycje recznie,
- pozwala wybrac, kto uczestniczy w kazdej pozycji,
- pozwala pominac pozycje z rozliczenia,
- kaucje pokazuje informacyjnie, a zwrot opakowan odejmuje od rachunku,
- liczy kto komu ma oddac pieniadze,
- zapisuje dane lokalnie na telefonie,
- opcjonalnie synchronizuje pokoj przez Firestore, jesli podasz konfiguracje Firebase.

Synchronizacja jest na etapie prototypu. Przed wspolnym uzywaniem trzeba
dopiac dostep do pokoju, reguly bazy i obsluge rownoczesnych zmian.
Kolejne zadania i warunki ich zakonczenia: [Plan prac](docs/ROADMAP.md).

## Ikona

Ikona Splitki jest ustawiona na Androidzie, iOS i w naglowku aplikacji.
Pliki zrodlowe i opis generowania: [Branding](assets/branding/README.md).
Po zmianie grafiki uruchom `dart run tool/generate_icons.dart`.

## Start lokalny

```powershell
flutter pub get
flutter run
```

Jesli masz kilka urzadzen:

```powershell
flutter devices
flutter run -d ID_URZADZENIA
```

## APK na Androida

Debug APK do szybkiego wrzucenia na telefon:

```powershell
flutter build apk --debug
```

Plik:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

Release APK bez chmury:

```powershell
flutter build apk --release
```

Plik:

```text
build\app\outputs\flutter-apk\app-release.apk
```

## Firebase

Bez Firebase apka dziala lokalnie. Z Firebase kilka telefonow moze wspoldzielic ten sam pokoj.

Build z chmura:

```powershell
flutter build apk --release `
  --dart-define=FIREBASE_API_KEY=... `
  --dart-define=FIREBASE_AUTH_DOMAIN=... `
  --dart-define=FIREBASE_PROJECT_ID=... `
  --dart-define=FIREBASE_STORAGE_BUCKET=... `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... `
  --dart-define=FIREBASE_APP_ID=...
```

Te same `--dart-define` dzialaja dla `flutter run`.

## iPhone

Na MacBooku:

```bash
flutter pub get
flutter run
```

Do instalacji poza App Store najwygodniej otworzyc:

```text
ios/Runner.xcworkspace
```

W Xcode wybierz swoje Apple ID w `Signing & Capabilities`, podlacz iPhone'a i uruchom `Runner` na telefonie.

## Przydatne kontrole

```powershell
flutter analyze
flutter test
```
