# Splitka: droga do wspolnego uzywania

Stan 2026-09-10. Kazdy numer to oddzielne zadanie do zlecenia w jednym prompcie.
Funkcje commitujemy osobno i wysylamy do Mortexer/Splitka.

## Co jest gotowe

- Projekt Flutter na Androida i iOS, interfejs Splitki i ikony obu platform.
- Domyslne osoby: Danus, Kubus, Damian. Wszyscy maja rowne uprawnienia.
- Reczne rachunki, edycja produktow, platnik i podzial pozycji na wybrane osoby.
- Pomijanie pozycji, rozliczenia w groszach, lokalny zapis i kasowanie rachunkow.
- Parser JSON Biedronki z rabatami, kaucjami i zwrotami oraz podstawowe testy.
- Konfiguracja Android/iOS dla Firebase splitka-18560, anonimowa tozsamosc,
  tworzenie mieszkania i dolaczanie przez prywatny kod zaproszenia.
- Reguly czlonkostwa oraz transakcyjne zmiany online bez porownywania zegarow.
- Dwie glowne zakladki: rachunki oraz listy zakupow; jedna lista wspolna i po
  jednej dla kazdego domownika, z dodawaniem, odhaczaniem i usuwaniem pozycji.
- Dowolna nazwa grupy oraz zarzadzanie maksymalnie 20 osobami: dodawanie,
  zmiana nazwy i koloru, dezaktywowanie i bezpieczne usuwanie.
- Wiele niezaleznych grup lokalnych i chmurowych z szybkim przelaczaniem.
- Testy kontrolera, formularzy i regul, w tym jednoczesny zapis dwoch klientow.

Nowa instalacja przechowuje rachunki lokalnie, dopoki nie utworzysz mieszkania
lub nie dolaczysz kodem. Zapis w mieszkaniu wymaga internetu; offline jest podglad.
APK mozna budowac lokalnie. Kompilacja i uruchomienie iOS wymagaja Maca.
Instrukcje konfiguracji i ograniczenia: [Firebase](FIREBASE.md).

## Kolejnosc prac

### 1. GitHub i automatyczne kontrole

Status: repo podlaczone i kod wyslany. Pozostalo GitHub Actions oraz wydania APK.

Podlaczyc wskazane przez uzytkownika repo do tego katalogu Flutter, wyslac
istniejace male commity i dodac GitHub Actions uruchamiajace analize i testy.
Nie dolaczac starego projektu Expo, plikow podpisu, danych osobistych ani build/.
APK do pobrania publikowac osobno jako wydania, gdy podpis bedzie gotowy.

Gotowe, gdy repo zawiera projekt Flutter i przechodzi pierwszy workflow.
Repo: https://github.com/Mortexer/Splitka.

### 2. Domkniecie lokalnych przeplywow

Status: poprawione konteksty dialogow, komunikaty po zapisie, Android Wstecz,
potwierdzenie usuwania pozycji i zachowanie formularzy po bledzie.
Testy widgetowe przechodza. Pozostal przeglad na fizycznym telefonie.

Naprawic i przetestowac kontekst dialogow i komunikatow w lib/main.dart:
stan SplitkaApp jest nad MaterialApp, a _confirm i _showSnack korzystaja
z jego context. Sprawdzic dodawanie, anulowanie, usuwanie, czyszczenie oraz
systemowy przycisk Wstecz na Androidzie. Dodac potwierdzenie lub cofanie
usuniecia pojedynczej pozycji. Komunikat sukcesu ma odpowiadac wynikowi zapisu.

Gotowe, gdy caly lokalny scenariusz dziala, dane przetrwaja restart, a testy
widgetowe obejmuja rzeczywiste klikniecia, nie tylko ekran startowy.

### 3. Import prawdziwych paragonow

Sprawdzic rzeczywisty biedra.json i kilka roznych eksportow: rabaty, produkty
wazone, wiele sztuk, kaucje, zwroty i uszkodzone dane. Porownac sumy z paragonem.
Dodac wykrywanie ponownego importu tego samego rachunku i czytelne ostrzezenia
o niezgodnej sumie. Testy przechowywac na zanonimizowanych danych.

Gotowe, gdy powtorny import nie podwaja dlugow, a kwoty zgadzaja sie co do grosza.
Kaucje nie obciazaja podzialu; zwrot pomniejsza wspolna kwote zgodnie z ustaleniem.
Rabat pomniejsza cene calej pozycji, a nie ponownie kazdej sztuki.

### 4. Konfiguracja Firebase dla obu platform

Status: obie aplikacje zarejestrowane w splitka-18560, pliki SDK dolaczone,
Anonymous Auth sprawdzone w prawdziwym projekcie. APK sie kompiluje.
Pozostalo uruchomienie iOS na Macu i porownanie z Androidem.

Utworzyc lub podlaczyc wskazany projekt Firebase na planie Spark, zarejestrowac
Androida i iOS oraz utworzyc Firestore. Dodac szablony konfiguracji i powtarzalne
komendy buildow. Rozdzielic identyfikatory aplikacji obu platform. Sprawdzic
polaczenie na srodowisku testowym; nie otwierac publicznie bazy na czas testu.

Gotowe, gdy obie konfiguracje inicjalizuja Firebase, a brak konfiguracji nadal
pozwala korzystac lokalnie. Wymaga projektu Firebase uzytkownika; wdrozenie
konfiguracji sprawdzamy w konsoli, nie tylko na podstawie samego kodu.

### 5. Prywatny pokoj bez ekranu rejestracji

Status: implementacja gotowa, 9 testow regul w emulatorze przechodzi.
Reguly opublikowano w splitka-18560 i sprawdzono logowanie oraz blokade obcego
klienta. Szczegoly sa w [Firebase](FIREBASE.md). Pozostal test zaproszenia
na dwoch fizycznych telefonach.

Dodac automatyczna anonimowa tozsamosc Firebase Auth, tworzenie mieszkania
i dolaczanie przez losowy kod zaproszenia. Reguly Firestore maja sprawdzac
czlonkostwo, format danych i rowne uprawnienia domownikow. Zablokowac obcym
odczyt oraz zapis. Sam przewidywalny identyfikator stancja nie jest ochrona.
Nie dodawac hasel ani formularzy zakladania kont. Przetestowac reguly emulatorem.

Gotowe, gdy zaproszona trojka edytuje wspolne dane, a obcy klient nie ma dostepu.

### 6. Synchronizacja bez gubienia zmian

Status: zapis online jest transakcyjny, ponawia operacje na najnowszych danych.
Rewizje zastapily zegary telefonow. Cache i potwierdzenie serwera sa rozrozniane,
spoznione odpowiedzi poprzedniego pokoju ignorowane, usuniete pozycje nie wracaja.
Test dwoch klientow w emulatorze zachowuje oba rownoczesnie dodane rachunki.

Pozostalo rozdzielenie calego dokumentu mieszkania na mniejsze rekordy/operacje,
trwala kolejka offline z ponawianiem po restarcie i migracja obecnego schematu 2.
Dopracowac komunikat konfliktu tej samej pozycji (teraz ostatni udany zapis wygrywa).
Nie obiecywac zapisu offline: aktualna wersja odrzuca go z komunikatem i zachowuje
formularz, a cache sluzy do podgladu.

Gotowe, gdy dwa telefony edytujace rozne pozycje nie kasuja sobie zmian,
a powrot internetu i restart aplikacji nie gubia oczekujacych zapisow.

### 7. Zamkniecie rozliczenia

Status: zwykle czyszczenie obejmuje tylko rachunki potwierdzane przez uzytkownika,
nie usuwa pozniejszych zakupow. Osobny przeplyw zamkniecia rozliczenia jest do zrobienia.

Dodac jawne zamkniecie calej rozliczonej puli po recznym oddaniu pieniedzy.
Pokazac kto komu placi, wymagac przypisania lub pominiecia pozostalych pozycji
i potwierdzenia. Usuwac tylko zatwierdzony zestaw rachunkow; nowe zakupy
drugiej osoby dodane w trakcie potwierdzania musza pozostac.
Nie wymagamy przechowywania historii zakupow ani integracji bankowej.

Gotowe, gdy po potwierdzeniu salda rozliczonej puli znikaja na wszystkich
telefonach, a nowy rachunek nie jest przypadkowo usuwany.

### 8. Docelowy APK i aktualizacje Androida

Ustawic wlasny klucz podpisu release, szablon key.properties.example,
numerowanie wersji i udokumentowac budowanie podpisanego APK. Obecnie release
uzywa klucza debug. Klucz i hasla maja pozostac poza Gitem, z kopia u wlasciciela.
Przetestowac aktualizacje podpisanej wersji bez utraty lokalnych danych.
Przejscie z obecnego APK debug-signed na inny podpis wymaga osobnej migracji
lub ponownej instalacji, wiec wczesniej zabezpieczyc istniejace rachunki.

Gotowe, gdy kolejne wydania mozna instalowac jako aktualizacje tej samej aplikacji.

### 9. iPhone na MacBooku

Uruchomic projekt w Xcode, skonfigurowac signing i Firebase dla iOS. Sprawdzic
ikone, wybor pliku JSON, klawiature, obszary bezpieczne i synchronizacje.
Wybrac instalacje testowa przez Xcode albo dystrybucje przez TestFlight.

Gotowe, gdy aplikacja dziala na fizycznym iPhonie i wspoldzieli dane z Androidem.
Potrzebne sa Mac/Xcode i iPhone. Darmowy Personal Team wymaga ponownego podpisu
po 7 dniach. TestFlight wymaga Apple Developer Program; standardowa cena to
99 USD rocznie lub lokalna cena. Sam Flutter nie usuwa tych wymagan Apple.

### 10. Wspolny test przed codziennym uzywaniem

Przejsc na 2-3 telefonach: dolaczenie do pokoju, import, wybor platnika,
podzial na jedna/dwie/trzy osoby, pominiecie, zwroty, edycje w tym samym czasie,
tryb samolotowy, restart, zamkniecie rozliczenia i aktualizacja aplikacji.
Sprawdzic maly ekran i powiekszony tekst. Dopisac regresje dla wykrytych bledow.

Gotowe, gdy wszyscy widza te same kwoty, grosze sie zgadzaja i dane nie gina
w zadnym z powyzszych scenariuszy. Wyniki zapisac w repo z wersja aplikacji.

## Pozniej, poza wymaganym pierwszym wydaniem

- Eksport/import kopii mieszkania do JSON na wypadek zmiany telefonu.
- Udostepnianie paragonu do Splitki z menu systemowego.
- Czastkowe splaty, powiadomienia i dalsze usprawnienia, jesli beda potrzebne.

## GitHub, Firebase czy Render

Wybrana propozycja: GitHub przechowuje kod, Flutter dziala na telefonach,
a Firebase Auth + Firestore odpowiadaja za dostep i wspolne rachunki.
Nie potrzeba uruchamiania serwera dla samej aplikacji mobilnej.

Firestore ma darmowy limit: 1 GiB danych, 50 000 odczytow i 20 000 zapisow
dziennie. Przy trzech osobach i prawidlowej synchronizacji powinien wystarczyc;
to ocena dla tej skali, nie gwarancja nieograniczonego uzycia.
Zrodlo: https://firebase.google.com/docs/firestore/quotas

Render bylby opcja dla osobnego backendu, ktorego teraz nie mamy. Darmowy
serwis zasypia po 15 minutach bez ruchu, lokalne pliki nie sa trwale,
a darmowy Postgres wygasa po 30 dniach. Nie daje to dobrej stalej bazy
za darmo dla tego projektu. Zrodlo: https://render.com/docs/free

Warunki instalacji iOS i czlonkostwa, sprawdzone 2026-09-09:
https://developer.apple.com/help/account/basics/about-your-developer-account
https://developer.apple.com/programs/enroll/
