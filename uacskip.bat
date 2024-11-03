@echo off
setlocal

:: check if any argument is passed
if "%~1"=="" (
    echo Drag and drop an application onto this script to create an UAC bypass shortcut.
    pause
    exit /b
)

:: try to elevate script
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrator privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
    exit /b
)

:: get app path and name without extension
set appPath="%*"
for %%F in (%appPath%) do set appName=%%~nF

echo Creating UAC bypass for %appName% (%appPath%)
echo.

set "taskName=NoUAC_%appName%"
set "taskFolder=NoUAC"
set "shortcutPath=%USERPROFILE%\Desktop\%appName%.lnk"

:: create task scheduler task
schtasks /create /tn "%taskFolder%\%taskName%" /tr '%appPath%' /sc once /st 00:00 /rl highest /f
if %errorlevel% neq 0 (
    echo Failed to create Task Scheduler task!
    pause
    exit /b
)

:: create desktop shortcut
set "targetPath=C:\Windows\System32\schtasks.exe"
set "arguments=/RUN /TN \"%taskFolder%\%taskName%\""
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%shortcutPath%'); $s.TargetPath='%targetPath%'; $s.Arguments='%arguments%'; $s.IconLocation='%appPath%,0'; $s.WindowStyle=7; $s.Save()"

echo Shortcut created: %shortcutPath%

pause
exit /b
