# MojeMMO – serwer

Ten folder zamienia komputer z Windows (64 bit) w serwer gry. Gracze łączą się
z nim grą z folderu **mmo install**.

## Instalacja (raz)

1. Skopiuj ten folder w miejsce bez polskich znaków w ścieżce, np. `C:\mmo server`
   (albo pobierz z GitHuba: **Code → Download ZIP** i rozpakuj).
2. Kliknij dwa razy **`Zainstaluj-serwer.bat`**. Skrypt:
   - pobierze SpacetimeDB **2.10.1** (oficjalne wydanie z GitHuba, ok. 45 MB) do podfolderu `spacetimedb`,
   - poprosi o zgodę administratora i otworzy w zaporze Windows **port 3000**,
   - uruchomi serwer w osobnym oknie **„Serwer MojeMMO (nie zamykaj)”**,
   - wgra moduł gry (`modul\mojemmo.wasm`),
   - zrobi skrót **Serwer MojeMMO** na pulpicie,
   - zapyta, czy uruchamiać serwer **automatycznie po włączeniu komputera**,
   - pokaże adresy dla graczy: lokalny (sieć domowa) i internetowy.

Serwer działa, dopóki jego okno jest otwarte.

## Granie przez internet

**Obecny sposób: sieć WireGuard.** Komputer z serwerem ma w tunelu WireGuard adres `10.10.1.5`
(sieć `10.10.0.0/16`); paczka gry jest zbudowana z tym adresem. Każdy gracz potrzebuje
własnej konfiguracji WireGuard w tej sieci. Zapora Windows przepuszcza port 3000 na
wszystkich kartach sieciowych (reguła z instalatora), więc także w tunelu.

Przekierowanie portu na routerze (poniżej) działa tylko przy publicznym adresie IP.
U obecnego dostawcy internetu komputer jest za kilkoma warstwami adresów prywatnych (CGNAT),
więc sama zmiana w routerze domowym nie wystarczy.

Żeby gracze spoza Twojej sieci domowej mogli się połączyć bez VPN (wymaga publicznego IP):
1. Na routerze przekieruj port **TCP 3000** na komputer z serwerem
   (adres lokalny pokazuje okno serwera, np. `192.168.0.6`).
   Zwykle: panel routera → „Przekierowanie portów” / „Port forwarding” / „Serwer wirtualny”.
2. Najlepiej ustaw w routerze stały adres lokalny dla tego komputera („rezerwacja DHCP”),
   żeby przekierowanie nie przestało działać po restarcie.
3. Adres internetowy (np. `185.241.199.210`) może się zmieniać u dostawcy internetu.
   Jeśli się zmieni, zbuduj paczkę gry z nowym adresem albo użyj darmowej nazwy DDNS
   (np. No-IP, DuckDNS) i podaj ją jako adres serwera.

## Codzienne użycie

| Plik | Co robi |
|---|---|
| `Uruchom-serwer.bat` (albo skrót na pulpicie) | uruchamia serwer i wgrywa aktualny moduł; **Enter** = postacie zostają, **W** = czyszczenie bazy |
| `Zatrzymaj-serwer.bat` | wyłącza serwer (to samo co zamknięcie jego okna) |

## Aktualizacja gry na serwerze

1. Podmień pliki na nowsze (zostaw podfoldery `spacetimedb` i `dane`).
2. Uruchom `Uruchom-serwer.bat`. Jeśli nowa wersja zmienia tabele (np. nowe pola postaci),
   wgrywanie się nie uda: uruchom jeszcze raz i wybierz **W** (postacie zostaną usunięte).

## Uwaga dla autora (komputer, na którym powstaje gra)

Serwer z tego folderu i serwer deweloperski (`spacetime start` z `start-mmo.bat`) używają
tego samego portu 3000, więc naraz działa tylko jeden. Mają osobne bazy danych.
Plik `modul\mojemmo.wasm` robi skrypt `tools\build_release.ps1`.

## Co jest w środku

| Ścieżka | Zawartość |
|---|---|
| `modul\mojemmo.wasm` | serwer gry (skompilowany `Lib.cs`) |
| `spacetimedb\` | programy SpacetimeDB (pobierane przy instalacji, nie ma ich w repozytorium) |
| `dane\` | baza danych: postacie, przedmioty (tworzona przy pierwszym uruchomieniu) |

Kopia zapasowa postaci: wyłącz serwer i skopiuj folder `dane`.
