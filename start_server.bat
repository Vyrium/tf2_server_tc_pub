@echo off
title TF2 Server - TC Pub

REM ============================================================
REM ABOUT -game tf2_server_tc_pub
REM This tells SRCDS to use THIS folder as the game directory.
REM It loads tf2_server_tc_pub\gameinfo.txt, which mounts:
REM   1) All server-specific content in this folder (cfg/maps/addons)
REM   2) The shared TF2 installation from ..\tf2_base\tf
REM This gives full isolation per server with a shared TF2 base.
REM ============================================================

REM Move to tf2_server root
cd /d "%~dp0.."

REM -------- RCON PASSWORD WARNING --------
set "RCON_WARN=1"
if exist "tf2_server_tc_pub\cfg\server.cfg" (
    findstr /I "rcon_password" "tf2_server_tc_pub\cfg\server.cfg" >nul && set "RCON_WARN="
)
if defined RCON_WARN (
    echo [WARN] No 'rcon_password' found in tf2_server_tc_pub\cfg\server.cfg
    echo [WARN] Set a strong rcon_password to secure your server.
    echo.
)

REM -------- AUTOMATIC IP DETECTION --------
REM Try to detect a non-loopback IPv4 using PowerShell.
for /f "tokens=*" %%I in ('powershell -NoProfile -Command "(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' -and $_.PrefixOrigin -ne 'WellKnown' } | Select-Object -First 1 -ExpandProperty IPAddress)"') do set SERVER_IP=%%I

if not defined SERVER_IP (
    echo [INFO] Could not auto-detect IPv4, defaulting to 0.0.0.0 (all interfaces).
    set SERVER_IP=0.0.0.0
) else (
    echo [INFO] Detected IPv4 address: %SERVER_IP%
)

REM -------- LOG FILE SETUP (timestamped) --------
set "LOGROOT=logs"
set "LOGSUB=pub"
if not exist "%LOGROOT%\%LOGSUB%" mkdir "%LOGROOT%\%LOGSUB%"

set "datestr=%date: =0%"
set "datestr=%datestr:/=-%"
set "timestr=%time: =0%"
set "timestr=%timestr::=-%"
set "LOGFILE=%LOGROOT%\%LOGSUB%\server_pub_%datestr%_%timestr%.log"

echo [INFO] Logging to %LOGFILE%
echo [INFO] Auto-restart enabled. Press CTRL+C to stop this server.
echo.

REM ============================================================
REM AUTO-RESTART LOOP
REM ============================================================
:loop
echo [PUB] Starting server at %DATE% %TIME% ...
tf2_base\srcds.exe ^
  -game tf2_server_tc_pub ^
  -console ^
  -secure ^
  -usercon ^
  -ip %SERVER_IP% ^
  -port 27016 ^
  -tickrate 66 ^
  -maxplayers 24 ^
  +exec server.cfg ^
  +map pl_upward >> "%LOGFILE%" 2>&1

echo [PUB] Server exited with code %ERRORLEVEL% at %DATE% %TIME%.
echo [PUB] Restarting in 5 seconds... Press CTRL+C to cancel.
timeout /t 5 /nobreak >nul
goto loop
