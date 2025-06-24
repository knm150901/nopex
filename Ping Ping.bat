@echo off
title Auto Ping Monitor with Response Time
color 0a
mode con:cols=62 lines=40
setlocal enabledelayedexpansion

:: Add Startup
set "startupFolder=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "shortcutPath=%startupFolder%\AutoPingMonitor.lnk"

:: Checkin Startup Shortcut 
if not exist "%shortcutPath%" (
    echo Membuat shortcut di Startup Folder...
    powershell -command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%shortcutPath%'); $Shortcut.TargetPath = '%~f0'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.Save()"
)


:: Host list for monitoring
set hosts=investor.fb.com cache.netflix.com ava.game.naver.com df.game.naver.com
:: Ping interval in seconds
set interval=5


:main_loop
cls

:: Get current datetime
for /f "tokens=1-3 delims=/: " %%a in ('time /t') do set waktu=%%a:%%b:%%c
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set tanggal=%%a/%%b/%%c

:: Get Color
for /f %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
set darkgray=%esc%[90m & set lightred=%esc%[91m & set lightgreen=%esc%[92m & set yellow=%esc%[93m & set lightblue=%esc%[94m & set magenta=%esc%[95m & set lightcyan=%esc%[96m & set white=%esc%[97m & set reset=%esc%[0m

echo ==============================================================
echo    AAAAA  U   U  TTTTT  OOOOO     PPPPP  II  NN   N  GGGGG
echo    A   A  U   U    T    O   O     P   P  II  NN   N  G 
echo    AAAAA  U   U    T    O   O     PPPPP  II  N  N N  G GGG
echo    A   A  U   U    T    O   O     P      II  N   NN  G   G
echo    A   A  UUUUU    T    OOOOO     P      II  N   NN  GGGGG
echo ===================%lightred%Auto Ping 1.0 by Namm%lightgreen%====================
echo.
echo     Last update: %yellow%%tanggal% %waktu%%lightgreen%
echo     Ping interval: %lightred%%interval%%lightgreen% seconds%lightgreen%
echo     Press CTRL+C to stop
echo. 
echo ==============================================================

:: Create index for hosts
set index=0
for %%h in (%hosts%) do (
    set /a index+=1
    set "host[!index!]=%%h"
)

:: Start all ping processes in parallel
set "ping_count=0"
for %%h in (%hosts%) do (
    set /a ping_count+=1
    start /b "" cmd /c "ping -n 1 %%h > ping_temp_!ping_count!.txt"
)

:: Wait for all ping processes to complete
:wait_loop
timeout /t 1 /nobreak >nul
tasklist /fi "imagename eq cmd.exe" /fi "windowtitle eq Ping_*" | find "cmd.exe" >nul
if not errorlevel 1 goto wait_loop

:: Process results
for /l %%i in (1,1,%ping_count%) do (
    for /f "tokens=*" %%f in ('dir /b ping_temp_%%i.txt 2^>nul') do (
        set "current_host=!host[%%i]!"
        
        :: Check if host is reachable
        find "TTL=" ping_temp_%%i.txt >nul
        if !errorlevel! equ 0 (
            for /f "tokens=7 delims== " %%t in ('find "time=" ping_temp_%%i.txt') do (
                set response_time=%%t
            )
            echo  %reset% [HOST] !current_host!
            echo   Status: %lightgreen%ONLINE%reset%
            echo   Response Time: !response_time!
        ) else (
            echo  %reset% [HOST] !current_host!
            echo   Status: %lightred%OFFLINE%reset%
            echo   Response Time: N/A
        )
        echo %lightgreen%------------------------------------------------------------
    )
)

:: Cleanup
del ping_temp_*.txt >nul 2>&1

:: Countdown
<nul set /p "=Next ping in: "
for /l %%i in (%interval%,-1,1) do (
    <nul set /p "=%%i "
    timeout /t 1 >nul
    <nul set /p "="
)
echo 0
goto main_loop