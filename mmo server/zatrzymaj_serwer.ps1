# Zatrzymuje serwer MojeMMO (dziala w tle, bez okna).
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "serwer_wspolne.ps1")

$procs = Get-Process spacetimedb-standalone -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $StdbServer }
if (-not $procs) { Ok "Serwer nie dziala."; exit 0 }
$procs | Stop-Process
Ok "Serwer zatrzymany."
