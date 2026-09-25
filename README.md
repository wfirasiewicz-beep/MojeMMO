# MojeMMO

Pixelartowe MMO w stylu klasycznego WoW: walka tab-target, kreator postaci
(ork, krasnolud, elf, kolory skóry, oczu, fryzury, zarost), potwory i wrogie postacie,
łup, ekwipunek widoczny na postaci.

## Jak zagrać (Windows 10/11, 64 bit)

0. Włącz tunel **WireGuard** z konfiguracją od autora gry (serwer ma adres `10.10.1.5` w tej sieci VPN).
1. Kliknij zielony przycisk **Code → Download ZIP** u góry tej strony i rozpakuj pobrany plik.
2. Wejdź do folderu **`mmo install`** i kliknij dwa razy **`Zainstaluj.bat`**.
3. Na oba pytania wciśnij **Enter** (domyślny folder i adres serwera).
4. Graj skrótem **MojeMMO** na pulpicie.

Jeśli Windows pokaże okno „System Windows ochronił ten komputer”,
kliknij **Więcej informacji → Uruchom mimo to**.

Szczegóły (sterowanie, zmiana serwera, problemy z połączeniem): [`mmo install/README.md`](mmo%20install/README.md).

## Co jest w repozytorium

| Folder | Dla kogo |
|---|---|
| [`mmo install`](mmo%20install) | **dla graczy**: gra i instalator |
| [`mmo server`](mmo%20server) | dla osoby, która stawia serwer gry ([instrukcja](mmo%20server/README.md)) |

Gra jest w folderze `mmo install/gra` pocięta na części `MojeMMO.zip.001`, `.002` …
(instalator skleja je sam).
