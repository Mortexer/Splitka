# Splitka

Mobilna apka Flutter do dzielenia rachunkow miedzy wspollokatorow.
Domyslne osoby: Danus, Kubus, Damian. Android i iOS, bez Expo.

## Co juz robi

- Importuje JSON paragonu Biedronki oraz reczne rachunki i produkty.
- Dzieli kazda pozycje na wybrane osoby albo pomija ja w rozliczeniu.
- Ma osobna zakladke list zakupow: wspolna oraz po jednej dla kazdej aktywnej osoby.
- Pozwala nazwac grupe oraz dodawac, edytowac i dezaktywowac do 20 osob.
- Pozwala dodawac, odhaczac i usuwac produkty z list zakupow.
- Kaucje pokazuje informacyjnie, zwroty opakowan zmniejszaja kwote.
- Liczy w groszach, kto komu ma oddac pieniadze.
- Zapisuje dane lokalnie; pozwala tworzyc wspolne mieszkanie w Firebase
  i dolaczac przez prywatny, czterocyfrowy kod zaproszenia. Rachunki i listy zakupow
  synchronizuja sie w ramach tego samego mieszkania.
- Korzysta z anonimowej tozsamosci, bez ekranu rejestracji.
- Synchronizuje zmiany online transakcjami, zachowuje ostatni podglad offline.
- Potwierdza usuwanie i nie zamyka formularzy po nieudanym zapisie.

Zapis wspolnych rachunkow wymaga internetu. Trwala kolejka offline, docelowy
podpis APK i test na fizycznym iPhonie sa jeszcze przed nami.
Szczegoly i warunki zakonczenia: [Plan prac](docs/ROADMAP.md).

## Start

Wymagany Flutter (sprawdzone na 3.41.6), Android SDK lub Mac z Xcode.

```powershell
flutter pub get
flutter devices
flutter run -d ID_URZADZENIA
```

Nowa instalacja zaczyna z rachunkami lokalnymi. Przycisk Grupa pozwala zarzadzac
uczestnikami, a sekcja udostepniania tworzy grupe w chmurze lub dolacza do niej.
Tylko jedna osoba tworzy grupe w chmurze; pozostali wklejaja jej kod.
[Firebase: konfiguracja, wdrozenie i testy](docs/FIREBASE.md).

## APK na Androida

```powershell
flutter build apk --release
```

Wynik: `build/app/outputs/flutter-apk/app-release.apk`.
Aplikacja zawiera konfiguracje Firebase `splitka-18560`; nie trzeba
przekazywac kluczy w poleceniu ani uruchamiac osobnego serwera.

Uwaga: obecny APK testowy uzywa klucza debug, mimo trybu release.
Docelowe podpisywanie i aktualizacje sa osobnym etapem planu.
Nie odinstalowuj aplikacji z lokalnymi rachunkami bez ich zabezpieczenia.

Build celowo pozbawiony synchronizacji:

```powershell
flutter build apk --release --dart-define=SPLITKA_LOCAL_ONLY=true
```

## iPhone

Na MacBooku:

```bash
flutter pub get
flutter build ios --debug --no-codesign
open ios/Runner.xcworkspace
```

W Xcode wybierz Runner, swoje konto w Signing & Capabilities i podlaczony
iPhone, a nastepnie uruchom aplikacje. Wymagany iOS 15.0+.
Konfiguracja Firebase iOS jest dolaczona. Builda i dzialania iOS nie mozna
zweryfikowac na Windowsie; trzeba wykonac je na Macu.
Sposob dlugoterminowej dystrybucji iPhone'a pozostaje do ustalenia.

## Kontrole

```powershell
flutter analyze
flutter test
npm.cmd ci
npm.cmd run test:rules
```

Node jest potrzebny tylko do narzedzi Firebase, nie do uruchamiania aplikacji.
Emulator regul wymaga Javy 21+. Testy uzywaja lokalnego `demo-splitka`,
nie prawdziwych rachunkow. Szczegoly: [Firebase](docs/FIREBASE.md).

## Ikona

Ikona jest ustawiona na Androidzie, iOS i w naglowku aplikacji.
Pliki i instrukcja: [Branding](assets/branding/README.md).
Po zmianie grafiki uruchom `dart run tool/generate_icons.dart`.

## Kod i backend

Repozytorium: [Mortexer/Splitka](https://github.com/Mortexer/Splitka).
Firebase Auth i Firestore obsluguja wspolne dane.
GitHub przechowuje kod; Render nie jest potrzebny.
