@echo off
title EffyUO - Aggiornamento
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; $f=Join-Path $env:TEMP 'effyuo-updater.ps1'; $w=New-Object Net.WebClient; $w.Headers.Add('User-Agent','EffyUO-Updater'); $w.DownloadFile('https://raw.githubusercontent.com/Gothoth95/EffyUO/main/updater/updater.ps1?t='+[DateTime]::UtcNow.Ticks,$f); & $f -Dir '%~dp0.'"
echo.
pause
