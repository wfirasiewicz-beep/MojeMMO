@echo off
rem Otwiera port 3000 w zaporze Windows (Windows zapyta o zgode administratora - kliknij Tak)
powershell -NoProfile -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0dodaj_zapore.ps1\"'"
