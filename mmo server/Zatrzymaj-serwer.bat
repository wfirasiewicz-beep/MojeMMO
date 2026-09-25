@echo off
rem Zatrzymuje serwer MojeMMO
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0zatrzymaj_serwer.ps1"
pause
