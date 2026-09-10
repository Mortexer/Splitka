# Firebase: Splitka

Projekt: `splitka-18560`. Konfiguracja mobilna jest juz w repo.
Render ani Expo nie uczestnicza w dzialaniu aplikacji.

Reguly z tego repo zostaly skompilowane i opublikowane 2026-09-10.
Po wdrozeniu sprawdzono prawdziwe logowanie anonimowe oraz odmowe odczytu
dla instalacji bez zaproszenia. Pelny przeplyw tworzenia i dolaczania zostal
sprawdzony w emulatorze; ostatnim krokiem jest test na dwoch telefonach.

## Publikacja regul

W konsoli Firebase powinny byc wlaczone Authentication > Sign-in method >
Anonymous oraz baza Cloud Firestore `(default)` w trybie Native/Standard.
Pozostaw plan Spark. Nie wlaczaj publicznego trybu testowego bazy.

W PowerShell w katalogu tego projektu:

```powershell
npm.cmd ci
npm.cmd run firebase:login -- --interactive
npm.cmd run firebase:deploy
```

Logowanie otwiera przegladarke. Wybierz konto z dostepem do `splitka-18560`.
Opcjonalne pytania o Gemini i statystyki mozna odrzucic. Nie przesylaj tokenow,
hasel ani pliku konta serwisowego w czacie lub do GitHuba.
Na Macu uzyj `npm` zamiast `npm.cmd`.

Ostatnia komenda publikuje tylko `firestore.rules` do wskazanego projektu.
Nie usuwa rachunkow. Nie wdraza serwera, hostingu ani funkcji platnych.
Przed publikacja przejrzyj obecne reguly, jesli projekt sluzy tez innym aplikacjom.

Alternatywa bez CLI: Cloud Firestore > Rules, zastap zawartosc plikiem
[`firestore.rules`](../firestore.rules) i kliknij Publish. Samo istnienie pliku
w repo nie zmienia regul w chmurze.

## Pierwsze telefony

1. Zainstaluj APK lub uruchom projekt na iPhonie przez Xcode.
2. Na jednym telefonie otworz Mieszkanie i wybierz Utworz mieszkanie.
   Lokalne rachunki tego telefonu trafia do nowego wspolnego mieszkania.
3. Otworz Mieszkanie ponownie i skopiuj kod zaproszenia.
4. Przeslij go prywatnie wspollokatorom. Na pozostalych telefonach wklej kod
   i wybierz Dolacz do mieszkania. Nie tworzcie trzech osobnych mieszkan.
5. Dodaj probny rachunek i zmien jego podzial na drugim telefonie.
   Obie instalacje powinny zobaczyc ten sam wynik.

Kod daje dostep do rachunkow. Nie publikuj go. Nie jest potrzebne zakladanie
widocznego konta: Firebase nadaje kazdej instalacji anonimowa tozsamosc.
Po reinstalacji lub wyczyszczeniu danych aplikacji dolacz ponownie tym samym kodem.
Rachunki lokalne sa osobne od wspolnych. Dolaczenie nie scala danych z dwoch
telefonow. Powrot do lokalnych nie usuwa rachunkow w chmurze ani czlonkostwa.

## Jak dziala zapis

- `/households/{id}`: mieszkanie, rachunki, listy zakupow i rosnaca rewizja,
  schemat 2. Lista `common` jest wspolna, pozostale maja ID domownikow.
- `/households/{id}/members/{uid}`: uprawnienie anonimowej instalacji.
- `/invites/{code}`: losowe zaproszenie 128-bit, bez mozliwosci listowania.
- Tylko czlonkowie czytaja i zmieniaja mieszkanie. Kazdy ma takie same prawa
  do rachunkow. Nazwa osoby w podziale nie jest kontem logowania.
- Utworzenie mieszkania, czlonkostwa i zaproszenia jest atomowe.
- Zmiana rachunku to transakcja na najnowszych danych. Konflikt powoduje
  ponowienie operacji; zegary telefonow nie decyduja o kolejnosci danych.
- Zapis chmurowy wymaga internetu. Offline zostaje podglad ostatniej kopii.
  Nieudana zmiana jest zglaszana, a formularz dodawania/edycji zachowuje dane.
  Nie ma jeszcze trwalej kolejki zmian offline.
- Edycja tego samego pola przez dwie osoby ma wynik ostatniego udanego zapisu.
  Zdalnie usunieta pozycja nie jest odtwarzana przez spozniona edycje.
- Na tym etapie mieszkanie jest jednym dokumentem Firestore (limit 1 MiB,
  dodatkowo reguly dopuszczaja do 500 rachunkow). Podzial na mniejsze rekordy,
  migracja i kolejka offline sa osobnym etapem planu.
- Zaproszenia nie maja jeszcze wygaszania/rotacji, a sklad domownikow jest staly.

## Konfiguracja aplikacji

Android: `pl.splitka.splitka_flutter`, plik `android/app/google-services.json`.
iOS: `pl.splitka.splitkaFlutter`, plik `ios/Runner/GoogleService-Info.plist`.
Identyfikatory roznia sie i sa rozrozniane wielkoscia liter.
`lib/storage/firebase_config.dart` wybiera odpowiednia aplikacje Firebase.
Konfiguracje SDK sa publicznymi identyfikatorami, nie kluczami administratora.
O dostepie do danych decyduja Auth i reguly, nie ukrywanie konfiguracji.

Zwykly `flutter build apk --release` zawiera konfiguracje chmury.
Osobny build tylko lokalny: `flutter build apk --release --dart-define=SPLITKA_LOCAL_ONLY=true`.
Desktop i web dzialaja tylko lokalnie; celem projektu sa Android oraz iOS.
iOS wymaga minimum 15.0, Maca i podpisania aplikacji w Xcode.

## Testy

```powershell
flutter analyze
flutter test
npm.cmd run test:rules
npm.cmd run firebase:check
```

Emulator wymaga Node 20+ i Javy 21+. `test:rules` uzywa tylko lokalnego projektu
`demo-splitka` na porcie 8085, nigdy nie kasuje danych `splitka-18560`.
Potrzebny jest wolny port 8085; emulator zamyka sie po testach.
Komunikaty PERMISSION_DENIED sa oczekiwane w testach niedozwolonego dostepu;
koncowy wynik wszystkich testow ma byc pozytywny.

Na tym komputerze Java 21 jest zainstalowana oddzielnie od Javy do Androida:

```powershell
$env:JAVA_HOME = "$env:USERPROFILE\.cache\splitka-tools\java21\jdk-21.0.12.1+1-jre"
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
npm.cmd run test:rules
```

`firebase:check` sprawdza prawdziwy projekt: tworzy jednego tymczasowego
uzytkownika anonimowego, potwierdza odmowe odczytu obcego mieszkania i usuwa
uzytkownika. Nie zapisuje rachunkow i nie wypisuje tokenow. Ten test sam
w sobie nie potwierdza synchronizacji zaproszonych telefonow.

## Diagnostyka

- Brak dostepu podczas tworzenia mieszkania: sprawdz, czy reguly opublikowano
  w projekcie `splitka-18560` i bazie `(default)`.
- Brak polaczenia: sprawdz internet oraz Anonymous w Authentication.
- Nie znaleziono kodu: wklej pelne zaproszenie z dzialajacego mieszkania,
  nie nazwe `stancja` ani ID projektu Firebase.
- Brak danych na drugim telefonie: sprawdz wspolny kod i status polaczenia.
  Sam start aplikacji pozostaje lokalny do utworzenia/dolaczenia do mieszkania.
- Nie usuwaj aplikacji w celu naprawy, zanim zabezpieczysz kod i rachunki lokalne.

Dokumentacja: [Flutter](https://firebase.google.com/docs/flutter/setup),
[Auth](https://firebase.google.com/docs/auth/flutter/anonymous-auth),
[transakcje](https://firebase.google.com/docs/firestore/manage-data/transactions),
[testowanie regul](https://firebase.google.com/docs/rules/unit-tests).
