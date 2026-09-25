# =====================================================================
#  Dodaje regule zapory Windows dla serwera MojeMMO (port TCP 3000).
#  Uruchamiany przez Dodaj-zapore.bat z uprawnieniami administratora.
# =====================================================================
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "serwer_wspolne.ps1")

$rule = "MojeMMO serwer (TCP $Port)"
Get-NetFirewallRule -DisplayName "$rule*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -DisplayName $rule -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -Profile Any | Out-Null
New-NetFirewallRule -DisplayName "$rule program" -Direction Inbound -Program $StdbServer -Action Allow -Profile Any | Out-Null
Ok "Zapora Windows przepuszcza port $Port (wszystkie sieci, takze WireGuard)."
Read-Host "Nacisnij Enter, zeby zamknac"
