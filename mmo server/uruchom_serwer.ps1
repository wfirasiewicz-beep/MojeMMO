# =====================================================================
#  Uruchamia serwer MojeMMO i wgrywa aktualny modul gry.
#  -Wyczysc : wgrywa modul z czyszczeniem bazy (wszystkie postacie znikaja).
#  -Auto    : bez pytan, dane zostaja (autostart razem z Windows).
# =====================================================================
param([switch]$Wyczysc, [switch]$Auto)
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "serwer_wspolne.ps1")

if (-not (Test-Path $StdbServer)) { Fail "Serwer nie jest zainstalowany. Uruchom najpierw 'Zainstaluj-serwer.bat'." }

if (-not $Wyczysc -and -not $Auto) {
    Write-Host "Enter = uruchom (postacie zostaja),  W + Enter = wyczysc baze (wszystkie postacie znikaja)"
    Write-Host "Po aktualizacji gry, ktora zmienia tabele (np. nowe pola postaci), trzeba wybrac W."
    $answer = Read-Host "Wybor"
    $Wyczysc = $answer -match '^[wW]'
}

Start-Stdb
if ($Auto) {
    # Autostart: bez czyszczenia; nieudana aktualizacja nie zatrzymuje serwera
    Publish-Module $false $true
} else {
    Publish-Module $Wyczysc
}
Show-Addresses
Ok "Serwer dziala w tle (bez okna). Wylaczysz go plikiem Zatrzymaj-serwer.bat."
