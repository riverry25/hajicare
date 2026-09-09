@echo off
setlocal enabledelayedexpansion

:: Configuration
set "URL_OS=windows_x86_64"
set "BINARY_NAME=android.exe"
set "INSTALL_DIR=%USERPROFILE%\AppData\AndroidCLI"
set "DOWNLOAD_URL=https://dl.google.com/android/cli/latest/!URL_OS!/!BINARY_NAME!"

echo Installing %BINARY_NAME%...

:: Create installation directory
if not exist "%INSTALL_DIR%" (
    mkdir "%INSTALL_DIR%"
)

:: Download the binary
set "TMP_FILE=%TEMP%\android_cli_launcher.tmp"
echo Downloading...
curl -fsSL "!DOWNLOAD_URL!" -o "!TMP_FILE!"
if %errorLevel% neq 0 (
    echo Error: Failed to download the binary from !DOWNLOAD_URL!.
    exit /b %errorLevel%
)

:: Move to the installation directory
echo Installing to %INSTALL_DIR%...
move /y "!TMP_FILE!" "%INSTALL_DIR%\%BINARY_NAME%"
if %errorLevel% neq 0 (
    echo Error: Failed to move the binary to %INSTALL_DIR%.
    exit /b %errorLevel%
)

:: Add to Registry if not already present
set "USER_PATH="
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
echo !USER_PATH! | findstr /i /c:"%INSTALL_DIR%" >nul
if %errorLevel% neq 0 (
    echo Adding %INSTALL_DIR% to user PATH...
    if "!USER_PATH!"=="" (
        set "NEW_PATH=%INSTALL_DIR%"
    ) else (
        set "NEW_PATH=!USER_PATH!;%INSTALL_DIR%"
    )
    reg add "HKCU\Environment" /v Path /t REG_EXPAND_SZ /d "!NEW_PATH!" /f >nul
)

:: Force first download/initialization
echo Initializing CLI...
set "ANDROID_CLI_FRESH_INSTALL=1"
"%INSTALL_DIR%\%BINARY_NAME%"

:: Add to current session if not already present
echo %PATH% | findstr /i /c:"%INSTALL_DIR%" >nul
if %errorLevel% neq 0 (
    endlocal && set "PATH=%PATH%;%INSTALL_DIR%"
)

:: Ensure endlocal
endlocal
echo ----------------------------------------
echo Success! android is ready to use.
echo %USERPROFILE%\AppData\AndroidCLI was added to the registry Path and the current cmd.
echo ----------------------------------------
