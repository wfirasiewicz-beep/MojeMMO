# =====================================================================
#  Instalator gry MojeMMO (klient).
#  1. skleja gre z czesci gra\MojeMMO.zip.001, .002 ... i rozpakowuje ja,
#  2. zapisuje adres serwera do serwer.txt (podpowiedz z gra\serwer_domyslny.txt),
#  3. sprawdza, czy serwer odpowiada,
#  4. tworzy skrot na pulpicie.
#  Nie wymaga uprawnien administratora.
# =====================================================================
$ErrorActionPreference = "Stop"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$gra = Join-Path $here "gra"

function Info ($m) { Write-Host "[i] $m" -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "[+] $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "[!] $m" -ForegroundColor Red; Read-Host "Nacisnij Enter, zeby zamknac"; exit 1 }

Write-Host ""
Write-Host "=== Instalacja MojeMMO ===" -ForegroundColor Yellow
if (Test-Path "$gra\wersja.txt") { Write-Host ("Wersja: " + (Get-Content "$gra\wersja.txt" -TotalCount 1)) }
Write-Host ""

# ----- Czesci gry: MojeMMO.zip.001, .002 ... (albo jeden MojeMMO.zip) -----
$parts = @(Get-ChildItem $gra -Filter "MojeMMO.zip.*" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -match '^\.\d+$' } | Sort-Object Name)
$single = Join-Path $gra "MojeMMO.zip"
if ($parts.Count -eq 0 -and -not (Test-Path $single)) { Fail "Brak plikow gry w folderze 'gra'. Pobierz caly folder 'mmo install'." }
for ($i = 0; $i -lt $parts.Count; $i++) {
    if ($parts[$i].Extension -ne (".{0:000}" -f ($i + 1))) { Fail "Brakuje czesci gry nr $($i + 1). Pobierz caly folder 'mmo install' jeszcze raz." }
}

# ----- 1. Folder instalacji -----
$default = Join-Path $env:LOCALAPPDATA "MojeMMO"
$dir = Read-Host "Gdzie zainstalowac gre? [Enter = $default]"
if ([string]::IsNullOrWhiteSpace($dir)) { $dir = $default }
$dir = $dir.Trim('"', ' ')

# ----- 2. Adres serwera -----
$suggest = "127.0.0.1"
if (Test-Path "$gra\serwer_domyslny.txt") { $suggest = (Get-Content "$gra\serwer_domyslny.txt" -TotalCount 1).Trim() }
Write-Host ""
Write-Host "Adres serwera gry (IP albo nazwa komputera z serwerem)."
Write-Host "Jesli nie wiesz, wcisnij Enter."
$server = Read-Host "Adres serwera [Enter = $suggest]"
if ([string]::IsNullOrWhiteSpace($server)) { $server = $suggest }
$server = $server.Trim()

# ----- 3. Sklejenie i rozpakowanie -----
$zip = $single
if ($parts.Count -gt 0) {
    Info "Skladam gre z $($parts.Count) czesci..."
    $zip = Join-Path $env:TEMP "MojeMMO_instalacja.zip"
    $out = [IO.File]::Create($zip)
    try { foreach ($p in $parts) { $in = [IO.File]::OpenRead($p.FullName); $in.CopyTo($out); $in.Close() } }
    finally { $out.Close() }
}

Info "Rozpakowuje gre do: $dir"
New-Item -ItemType Directory -Force $dir | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
try { $archive = [System.IO.Compression.ZipFile]::OpenRead($zip) }
catch { Fail "Plik gry jest uszkodzony. Pobierz folder 'mmo install' jeszcze raz. ($($_.Exception.Message))" }
try {
    foreach ($e in $archive.Entries) {
        $target = Join-Path $dir $e.FullName
        if ($e.FullName.EndsWith("/") -or $e.FullName.EndsWith("\")) { New-Item -ItemType Directory -Force $target | Out-Null; continue }
        New-Item -ItemType Directory -Force (Split-Path $target) | Out-Null
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($e, $target, $true)
    }
} catch {
    Fail "Nie udalo sie rozpakowac. Czy gra jest wlaczona? Zamknij ja i sprobuj ponownie. ($($_.Exception.Message))"
} finally {
    $archive.Dispose()
    if ($parts.Count -gt 0) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }   # tylko nasz plik tymczasowy
}

# Pliki pobrane z internetu Windows oznacza jako "niezaufane"; zdejmujemy to oznaczenie
Get-ChildItem $dir -Recurse -File | Unblock-File -ErrorAction SilentlyContinue

# ----- 4. Adres serwera i pomocniczy skrypt do jego zmiany -----
Set-Content (Join-Path $dir "serwer.txt") -Encoding ascii -Value @(
    "# Adres serwera gry: IP komputera z serwerem, np. 192.168.1.20 (port 3000 dopisze sie sam)",
    $server)

Set-Content (Join-Path $dir "Zmien serwer.bat") -Encoding ascii -Value @(
    "@echo off",
    "set /p ADDR=Nowy adres serwera (np. 192.168.1.20): ",
    "if ""%ADDR%""=="""" exit /b",
    "echo # Adres serwera gry> ""%~dp0serwer.txt""",
    "echo %ADDR%>> ""%~dp0serwer.txt""",
    "echo Zapisano: %ADDR%",
    "pause")
Ok "Adres serwera: $server (zmienisz go plikiem 'Zmien serwer.bat' w folderze gry)"

# Czy serwer odpowiada (port 3000, chyba ze adres ma wlasny port)
$hostName = $server -replace '^[a-z]+://', '' -replace '/.*$', ''
$port = 3000
if ($hostName -match '^(.+):(\d+)$') { $hostName = $Matches[1]; $port = [int]$Matches[2] }
$client = New-Object System.Net.Sockets.TcpClient
try {
    $task = $client.ConnectAsync($hostName, $port)
    if ($task.Wait(4000) -and $client.Connected) { Ok "Serwer $hostName`:$port odpowiada." }
    else { Warn "Serwer $hostName`:$port teraz nie odpowiada. Gra polaczy sie, gdy serwer bedzie wlaczony." }
} catch { Warn "Serwer $hostName`:$port teraz nie odpowiada. Gra polaczy sie, gdy serwer bedzie wlaczony." }
finally { $client.Close() }

# ----- 5. Skrot na pulpicie -----
$exe = Join-Path $dir "MojeMMO.exe"
try {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "MojeMMO.lnk"))
    $lnk.TargetPath = $exe
    $lnk.WorkingDirectory = $dir
    $lnk.Save()
    Ok "Skrot 'MojeMMO' na pulpicie."
} catch { Info "Nie udalo sie zrobic skrotu. Gre uruchomisz z: $exe" }

Write-Host ""
Ok "Instalacja zakonczona."
$run = Read-Host "Uruchomic gre teraz? [T/n]"
if ($run -notmatch '^[nN]') { Start-Process -FilePath $exe -WorkingDirectory $dir }
