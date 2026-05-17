@echo off
setlocal

:: 1. Dynamic Path Detection (No hardcoded roots)
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"

:: 2. Configure Local .tmp Cache (Host Leakage Prevention)
set "TMPDIR=%ROOT%\.tmp"
set "npm_config_cache=%TMPDIR%\npm-cache"
set "NODE_ENV=production"

if not exist "%TMPDIR%" mkdir "%TMPDIR%"
if not exist "%TMPDIR%\npm-cache" mkdir "%TMPDIR%\npm-cache"

:: 3. Register local node/npm onto temporary PATH
:: We assume node binaries are downloaded/placed in %ROOT%\runtime\windows-x64
set "NODE_BIN=%ROOT%\runtime\windows-x64"
set "PATH=%NODE_BIN%;%PATH%"

echo ==================================================
echo [Hermes] Starting Portable Shell ^& Path Virtualizer
echo [Hermes] ROOT=%ROOT%
echo [Hermes] CACHE=%TMPDIR%
echo ==================================================

:: Install dependencies if node_modules does not exist
if not exist "%ROOT%\node_modules" (
    echo [Hermes] Installing core dependencies locally...
    call npm install --cache "%npm_config_cache%"
)

:: 4. Start Core Execution
echo [Hermes] Launching Engine...
call npm start

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [Hermes] Engine exited with error code %ERRORLEVEL%.
    pause
)
exit /b %ERRORLEVEL%
