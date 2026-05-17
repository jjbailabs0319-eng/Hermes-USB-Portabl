@echo off
setlocal

:: 1. Dynamic Path Detection (No hardcoded roots)
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"

:: 2. Configure Local .tmp Cache & Isolation (Zero-Trace)
set "TMPDIR=%ROOT%\.tmp"
set "UV_CACHE_DIR=%TMPDIR%\uv-cache"
set "HERMES_HOME=%ROOT%\data"
set "PYTHONUTF8=1"

if not exist "%TMPDIR%" mkdir "%TMPDIR%"
if not exist "%UV_CACHE_DIR%" mkdir "%UV_CACHE_DIR%"
if not exist "%HERMES_HOME%" mkdir "%HERMES_HOME%"

:: 3. Download Portable uv if missing
set "UV_BIN=%TMPDIR%\bin"
set "PATH=%UV_BIN%;%PATH%"

if not exist "%UV_BIN%\uv.exe" (
    echo [Hermes] Downloading Portable 'uv' package manager...
    if not exist "%UV_BIN%" mkdir "%UV_BIN%"
    curl -LsSf https://github.com/astral-sh/uv/releases/latest/download/uv-x86_64-pc-windows-msvc.zip -o "%TMPDIR%\uv.zip"
    powershell -Command "Expand-Archive -Path '%TMPDIR%\uv.zip' -DestinationPath '%TMPDIR%\uv-extracted' -Force"
    copy /y "%TMPDIR%\uv-extracted\uv-x86_64-pc-windows-msvc\uv.exe" "%UV_BIN%\uv.exe"
    copy /y "%TMPDIR%\uv-extracted\uv-x86_64-pc-windows-msvc\uvx.exe" "%UV_BIN%\uvx.exe"
    rmdir /s /q "%TMPDIR%\uv-extracted"
    del "%TMPDIR%\uv.zip"
)

echo ==================================================
echo [Hermes] Starting Portable V2 (NousResearch Merge)
echo [Hermes] ROOT=%ROOT%
echo [Hermes] HERMES_HOME=%HERMES_HOME%
echo ==================================================

:: 4. Setup Python Virtual Environment using uv
cd "%ROOT%"
if not exist "%TMPDIR%\.venv" (
    echo [Hermes] Creating isolated Python 3.11 environment...
    call uv venv "%TMPDIR%\.venv" --python 3.11
    
    echo [Hermes] Installing core Hermes Agent dependencies...
    set "VIRTUAL_ENV=%TMPDIR%\.venv"
    set "PATH=%TMPDIR%\.venv\Scripts;%PATH%"
    call uv pip install -e ".[all]"
) else (
    set "VIRTUAL_ENV=%TMPDIR%\.venv"
    set "PATH=%TMPDIR%\.venv\Scripts;%PATH%"
)

:menu
cls
echo ==================================================
echo [Hermes] Portable V2 Dashboard
echo ==================================================
echo 1. Start Hermes CLI (TUI)
echo 2. Start Hermes Gateway (Telegram/Discord)
echo 3. Start Setup Wizard (Initial Config)
echo 4. Portable Command Prompt
echo 0. Exit
echo.
set /p choice="Select: "

if "%choice%"=="1" (
    call hermes
    pause
    goto menu
) else if "%choice%"=="2" (
    call hermes gateway start
    pause
    goto menu
) else if "%choice%"=="3" (
    call hermes setup
    pause
    goto menu
) else if "%choice%"=="4" (
    echo [Hermes] Type 'exit' to return to menu.
    cmd /k
    goto menu
) else if "%choice%"=="0" (
    exit /b 0
) else (
    goto menu
)
