# =====================================================================
#  Instalacja serwera MojeMMO na tym komputerze:
#    1. pobiera SpacetimeDB (dokladnie wersje, z ktora dziala gra),
#    2. otwiera port 3000 w zaporze Windows (prosi o uprawnienia administratora),
#    3. uruchamia serwer i wgrywa modul gry,
#    4. robi skrot "Serwer MojeMMO" na pulpicie,
#    5. pokazuje adresy, ktore gracze wpisuja w grze.
# =====================================================================
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "serwer_wspolne.ps1")

Write-Host ""
Write-Host "=== Instalacja serwera MojeMMO ===" -ForegroundColor Yellow
Write-Host ""

Install-Stdb

# ----- Zapora: port 3000 dla innych komputerow w sieci -----
$rule = "MojeMMO serwer (TCP $Port)"
if (Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue) {
    Ok "Regula zapory juz istnieje."
} else {
    Info "Dodaje regule zapory dla portu $Port (Windows zapyta o zgode administratora)..."
    $fw = "New-NetFirewallRule -DisplayName '$rule' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Any | Out-Null; " +
          "New-NetFirewallRule -DisplayName '$rule program' -Direction Inbound -Program '$StdbServer' -Action Allow -Profile Any | Out-Null"
    try {
        Start-Process powershell -Verb RunAs -Wait -ArgumentList @("-NoProfile", "-Command", $fw)
        if (Get-NetFirewallRule -DisplayName $rule -ErrorAction SilentlyContinue) { Ok "Port $Port otwarty w zaporze." }
        else { Warn "Nie udalo sie dodac reguly. Inne komputery moga sie nie polaczyc (patrz README)." }
    } catch { Warn "Brak zgody administratora. Inne komputery moga sie nie polaczyc (patrz README)." }
}

Start-Stdb
Publish-Module $false

# ----- Skrot na pulpicie -----
try {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath("Desktop")) "Serwer MojeMMO.lnk"))
    $lnk.TargetPath = Join-Path $Here "Uruchom-serwer.bat"
    $lnk.WorkingDirectory = $Here
    $lnk.Save()
    Ok "Skrot 'Serwer MojeMMO' na pulpicie (uruchamia serwer po restarcie komputera)."
} catch { }

# ----- Autostart razem z Windows (opcjonalnie) -----
$startup = Join-Path ([Environment]::GetFolderPath("Startup")) "Serwer MojeMMO.lnk"
if ((Read-Host "Uruchamiac serwer automatycznie po wlaczeniu komputera? [T/N]") -match '^[tT]') {
    try {
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut($startup)
        $lnk.TargetPath = "powershell.exe"
        $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Minimized -File `"$(Join-Path $Here 'uruchom_serwer.ps1')`" -Auto"
        $lnk.WorkingDirectory = $Here
        $lnk.WindowStyle = 7   # zminimalizowane
        $lnk.Save()
        Ok "Autostart wlaczony (wylaczysz go, usuwajac skrot 'Serwer MojeMMO' z folderu Autostart: Win+R, shell:startup)."
    } catch { Warn "Nie udalo sie wlaczyc autostartu." }
}

Show-Addresses
Ok "Instalacja zakonczona. Serwer dziala, dopoki jest otwarte jego okno."
