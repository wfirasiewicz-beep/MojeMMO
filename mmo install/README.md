# MojeMMO – gra (instalacja dla graczy)

MMO w stylu klasycznego WoW: walka tab-target, kreator postaci (ork, krasnolud, elf),
potwory, łup, ekwipunek widoczny na postaci. Gra łączy się z serwerem autora.

## Instalacja (Windows 10/11, 64 bit)

1. Pobierz ten folder: na GitHubie **Code → Download ZIP**, potem rozpakuj ZIP.
2. Kliknij dwa razy **`Zainstaluj.bat`**.
3. Folder instalacji: wciśnij **Enter** (domyślnie `%LOCALAPPDATA%\MojeMMO`).
4. Adres serwera: wciśnij **Enter** (adres serwera autora jest już wpisany).
5. Gotowe: na pulpicie pojawi się skrót **MojeMMO**.

Jeśli Windows pokaże niebieskie okno „System Windows ochronił ten komputer”,
kliknij **Więcej informacji → Uruchom mimo to** (gra nie ma płatnego podpisu cyfrowego).

## Sterowanie

| Klawisz | Działanie |
|---|---|
| W / S | przód / tył |
| A / D | chód bokiem |
| Spacja | skok |
| LPM na wrogu | zaznaczenie celu; kolejne LPM = atak |
| PPM przytrzymany | obrót kamery razem z postacią |
| LPM + PPM | bieg do przodu |
| 1–5 | umiejętności |
| 6 / 7 | mikstura zdrowia / many |
| Tab / Esc | odznaczenie celu |
| I | ekwipunek |
| M | mapa |

## Zmiana serwera

W folderze gry jest **`Zmien serwer.bat`**. Możesz też edytować `serwer.txt`
(pierwsza linia bez `#` to adres, np. `192.168.1.20` albo `192.168.1.20:3000`).

## Aktualizacja

Pobierz nowszą wersję folderu i uruchom `Zainstaluj.bat` jeszcze raz, do tego samego folderu.
Twoja postać zostaje na serwerze.

## Gdy nie da się połączyć

- Serwer może być akurat wyłączony: spróbuj później.
- Sprawdź adres w `serwer.txt`.
- Gracze w tej samej sieci domowej co serwer mogą potrzebować adresu lokalnego
  serwera (np. `192.168.0.6`) zamiast adresu internetowego.

## Wymagania

Windows 10/11 64 bit, karta graficzna z OpenGL 3.3 albo DirectX 11.

---

## Dla autora gry

- Pliki w `gra\` robi skrypt `tools\build_release.ps1` w projekcie MojeMMO:
  `.\build_release.ps1 -Adres <adres serwera>`. Gra jest pocięta na części po 20 MB
  (`MojeMMO.zip.001`, `.002` …), bo strona GitHuba przyjmuje pliki do 25 MB;
  `Zainstaluj.bat` skleja je sam.
- Wysyłanie na GitHub przez przeglądarkę: repozytorium → **Add file → Upload files**,
  przeciągnij całą zawartość tego folderu (razem z folderem `gra`) → **Commit changes**.
  Przy aktualizacji wyślij pliki jeszcze raz; nieaktualne części `MojeMMO.zip.0xx`
  usuń na GitHubie, jeśli nowa wersja ma ich mniej.
