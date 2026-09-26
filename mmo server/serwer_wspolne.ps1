# =====================================================================
#  Wspolne ustawienia i funkcje skryptow serwera MojeMMO.
#  Dolaczany przez instaluj_serwer.ps1, uruchom_serwer.ps1 i zatrzymaj_serwer.ps1.
# =====================================================================
$ErrorActionPreference = "Stop"

$Here       = Split-Path -Parent $MyInvocation.MyCommand.Path
$StdbVer    = "2.10.1"                                   # ta sama wersja co SDK w grze
$StdbDir    = Join-Path $Here "spacetimedb"              # pobrane programy SpacetimeDB
$StdbCli    = Join-Path $StdbDir "spacetimedb-cli.exe"
$StdbServer = Join-Path $StdbDir "spacetimedb-standalone.exe"
$DataDir    = Join-Path $Here "dane"                     # baza danych gry (postacie, przedmioty)
$Wasm       = Join-Path $Here "modul\mojemmo.wasm"       # skompilowany serwer gry (Lib.cs)
$DbName     = "mojemmo"
$Port       = 3000
$LocalUrl   = "http://127.0.0.1:$Port"
$StdbZipUrl = "https://github.com/clockworklabs/SpacetimeDB/releases/download/v$StdbVer/spacetime-x86_64-pc-windows-msvc.zip"

function Info ($m) { Write-Host "[i] $m" -ForegroundColor Cyan }
function Ok   ($m) { Write-Host "[+] $m" -ForegroundColor Green }
function Warn ($m) { Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail ($m) { Write-Host "[!] $m" -ForegroundColor Red; Read-Host "Nacisnij Enter, zeby zamknac"; exit 1 }

function Test-Port ($port) {
    $c = New-Object System.Net.Sockets.TcpClient
    try { $c.Connect("127.0.0.1", $port); $c.Close(); return $true } catch { return $false }
}

function Wait-ForPort ($port, $seconds) {
    $end = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $end) { if (Test-Port $port) { return $true }; Start-Sleep -Milliseconds 500 }
    return $false
}

# Pobiera SpacetimeDB (oficjalne wydanie z GitHuba), jesli jeszcze go nie ma.
function Install-Stdb {
    if ((Test-Path $StdbCli) -and (Test-Path $StdbServer)) { Ok "SpacetimeDB $StdbVer jest juz pobrany."; return }
    Info "Pobieram SpacetimeDB $StdbVer (ok. 45 MB)..."
    New-Item -ItemType Directory -Force $StdbDir | Out-Null
    $zip = Join-Path $StdbDir "spacetime.zip"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = "SilentlyContinue"
    Invoke-WebRequest $StdbZipUrl -OutFile $zip -UseBasicParsing
    Expand-Archive $zip $StdbDir -Force
    Remove-Item $zip -Force
    Get-ChildItem $StdbDir -File | Unblock-File -ErrorAction SilentlyContinue
    if (-not (Test-Path $StdbServer)) { Fail "Po rozpakowaniu brak spacetimedb-standalone.exe." }
    Ok "SpacetimeDB pobrany do: $StdbDir"
}

# Klucze do podpisywania tokenow logowania graczy (JWT, ECDSA P-256), tworzone raz na tym komputerze.
# Polecenie "spacetime start" robi to samo w swoim folderze konfiguracji; samodzielny serwer
# wymaga podania ich wprost. Utrata kluczy = gracze musza zalozyc postacie od nowa.
$KeyDir  = Join-Path $Here "klucze"
$PrivKey = Join-Path $KeyDir "id_ecdsa"
$PubKey  = Join-Path $KeyDir "id_ecdsa.pub"

function ConvertTo-Pem ([byte[]]$der, [string]$label) {
    $b64 = [Convert]::ToBase64String($der)
    $lines = for ($i = 0; $i -lt $b64.Length; $i += 64) { $b64.Substring($i, [Math]::Min(64, $b64.Length - $i)) }
    return "-----BEGIN $label-----`n" + ($lines -join "`n") + "`n-----END $label-----`n"
}

function Initialize-Keys {
    if ((Test-Path $PrivKey) -and (Test-Path $PubKey)) { return }
    Info "Tworze klucze serwera (raz)..."
    New-Item -ItemType Directory -Force $KeyDir | Out-Null
    Add-Type -AssemblyName System.Core
    $params = New-Object System.Security.Cryptography.CngKeyCreationParameters
    $params.ExportPolicy = [System.Security.Cryptography.CngExportPolicies]::AllowPlaintextExport
    $key = [System.Security.Cryptography.CngKey]::Create([System.Security.Cryptography.CngAlgorithm]::ECDsaP256, $null, $params)
    try {
        $pkcs8 = $key.Export([System.Security.Cryptography.CngKeyBlobFormat]::Pkcs8PrivateBlob)
        $blob = $key.Export([System.Security.Cryptography.CngKeyBlobFormat]::EccPublicBlob)   # 8 bajtow naglowka + X + Y
        # SubjectPublicKeyInfo dla P-256: stala czesc ASN.1 + punkt nieskompresowany (04 X Y)
        $prefix = [byte[]](0x30,0x59,0x30,0x13,0x06,0x07,0x2A,0x86,0x48,0xCE,0x3D,0x02,0x01,0x06,0x08,0x2A,0x86,0x48,0xCE,0x3D,0x03,0x01,0x07,0x03,0x42,0x00,0x04)
        $spki = $prefix + $blob[8..71]
        [IO.File]::WriteAllText($PrivKey, (ConvertTo-Pem $pkcs8 "PRIVATE KEY"), [Text.Encoding]::ASCII)
        [IO.File]::WriteAllText($PubKey, (ConvertTo-Pem ([byte[]]$spki) "PUBLIC KEY"), [Text.Encoding]::ASCII)
    } finally { $key.Dispose() }
    Ok "Klucze serwera zapisane w: $KeyDir (kopia zapasowa razem z folderem 'dane')"
}

# Uruchamia serwer w tle, BEZ okna konsoli: dziennik trafia do plikow dane\serwer.log i dane\serwer_bledy.log.
# (Okno konsoli bylo pulapka: klikniecie w nie wlacza w Windows "Szybka edycje" i wstrzymuje serwer
#  przy najblizszym wypisaniu tekstu; serwer stal wtedy, az ktos wcisnal Esc.)
# Serwer dziala, dopoki nie uzyjesz Zatrzymaj-serwer.bat albo nie wylaczysz komputera.
$LogFile = Join-Path $DataDir "serwer.log"
$ErrFile = Join-Path $DataDir "serwer_bledy.log"

function Start-Stdb {
    if (Test-Port $Port) { Ok "Serwer juz dziala na porcie $Port."; return }
    New-Item -ItemType Directory -Force $DataDir | Out-Null
    Initialize-Keys
    Info "Uruchamiam serwer w tle (dziennik: $LogFile)..."
    $srvArgs = @("start", "--data-dir", "`"$DataDir`"", "--listen-addr", "0.0.0.0:$Port",
                 "--jwt-priv-key-path", "`"$PrivKey`"", "--jwt-pub-key-path", "`"$PubKey`"")
    Start-Process -FilePath $StdbServer -ArgumentList $srvArgs -WindowStyle Hidden `
        -RedirectStandardOutput $LogFile -RedirectStandardError $ErrFile | Out-Null
    if (-not (Wait-ForPort $Port 60)) { Fail "Serwer nie wstal w ciagu 60 sekund. Zobacz: $ErrFile" }
    Ok "Serwer dziala (w tle, bez okna)."
}

# Wgrywa (albo aktualizuje) modul gry. $wipe = czysci baze (np. po duzej zmianie tabel).
# $soft = true: blad nie zamyka skryptu (autostart), tylko ostrzega.
function Publish-Module ([bool]$wipe, [bool]$soft = $false) {
    if (-not (Test-Path $Wasm)) { Fail "Brak pliku modul\mojemmo.wasm." }
    $pubArgs = @("publish", "--server", $LocalUrl, "--bin-path", $Wasm, $DbName, "--yes")
    if ($wipe) { $pubArgs += "--delete-data" }
    Info "Wgrywam modul gry..."
    & $StdbCli @pubArgs
    if ($LASTEXITCODE -ne 0) {
        Warn "Wgrywanie nie powiodlo sie. Jesli komunikat mowi o zmianie schematu tabel,"
        Warn "uruchom 'Uruchom-serwer.bat' i wybierz czyszczenie bazy (opcja W)."
        if ($soft) { Warn "Serwer dziala dalej ze stara wersja gry."; return }
        Fail "Blad publikacji modulu."
    }
    Ok "Modul gry wgrany."
}

# Adresy, ktore gracze wpisuja w instalatorze gry.
function Show-Addresses {
    $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
           Where-Object { $_.IPAddress -notmatch '^(127\.|169\.254\.)' } | ForEach-Object IPAddress
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host " Gracze wpisuja w grze (serwer.txt) jeden z adresow:" -ForegroundColor Yellow
    foreach ($ip in $ips) { Write-Host "    $ip   (ta sama siec domowa)" -ForegroundColor White }
    Write-Host "    127.0.0.1   (tylko na tym komputerze)" -ForegroundColor DarkGray
    try {
        $public = Invoke-RestMethod "https://api.ipify.org" -TimeoutSec 5 -UseBasicParsing
        Write-Host "    $public   (przez internet: wymaga przekierowania portu $Port na routerze)" -ForegroundColor White
    } catch { }
    Write-Host " Port: $Port" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host ""
}
