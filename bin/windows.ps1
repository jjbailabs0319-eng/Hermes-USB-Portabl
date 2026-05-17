$ErrorActionPreference = "Stop"

$Root = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot ".."))
$Platform = "windows-x64"
. (Join-Path $PSScriptRoot "portable-env.ps1") -Root $Root -Platform $Platform

$NodeVersion = "v20.11.1"
$NodeZip = "node-$NodeVersion-win-x64.zip"
$NodeUrl = "https://nodejs.org/dist/$NodeVersion/$NodeZip"
$DownloadPath = Join-Path $Root "runtime\downloads\$NodeZip"
$NodeFinal = Join-Path $Root "runtime\$Platform"
$NodeExe = Join-Path $NodeFinal "node.exe"
$NpmCmd = Join-Path $NodeFinal "npm.cmd"

function Write-Step([string]$Text) {
  Write-Host "[portable-hermes-agent] $Text" -ForegroundColor Cyan
}

function Install-NodeIfNeeded {
  if (Test-Path -LiteralPath $NodeExe) {
    Write-Step "Portable Node already exists for $Platform"
    return
  }

  Write-Step "Downloading portable Node $NodeVersion for $Platform"
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $DownloadPath), (Join-Path $Root "runtime") | Out-Null
  Invoke-WebRequest -Uri $NodeUrl -OutFile $DownloadPath -UseBasicParsing

  Write-Step "Extracting portable Node"
  $extractParent = Join-Path $Root "runtime"
  Expand-Archive -LiteralPath $DownloadPath -DestinationPath $extractParent -Force
  $extracted = Join-Path $extractParent "node-$NodeVersion-win-x64"
  Remove-Item -LiteralPath $NodeFinal -Recurse -Force -ErrorAction SilentlyContinue
  Move-Item -LiteralPath $extracted -Destination $NodeFinal
}

function Install-HermesDependenciesIfNeeded {
  $nodeModules = Join-Path $Root "node_modules"
  if (-not (Test-Path -LiteralPath $nodeModules)) {
    Write-Step "Installing Hermes Agent Core dependencies..."
    $process = Start-Process -FilePath $NpmCmd -ArgumentList "install" -WorkingDirectory $Root -Wait -NoNewWindow -PassThru
    if ($process.ExitCode -ne 0) {
      throw "Failed to install Hermes dependencies"
    }
  } else {
    Write-Step "Hermes Agent Core dependencies already installed"
  }
}

function Show-Header {
  Clear-Host
  Write-Host "Portable Hermes Agent" -ForegroundColor Cyan
  Write-Host ("-" * 72) -ForegroundColor DarkGray
  Write-Host "Root      $Root"
  Write-Host "Platform  $Platform"
  Write-Host "Data      $env:HERMES_AGENT_STATE_DIR"
  Write-Host "Workspace $env:HERMES_AGENT_PORTABLE_WORKSPACE"
  Write-Host ("-" * 72) -ForegroundColor DarkGray
}

Install-NodeIfNeeded
. (Join-Path $PSScriptRoot "portable-env.ps1") -Root $Root -Platform $Platform
Install-HermesDependenciesIfNeeded

Write-Step "Portable runtime ready"
& $NodeExe --version

while ($true) {
  Show-Header
  Write-Host "1. Start Hermes Agent Core"
  Write-Host "2. Portable Shell"
  Write-Host "0. Exit"
  Write-Host

  $choice = Read-Host "Select"
  switch ($choice) {
    "1" { 
        Write-Step "Starting Hermes Agent..."
        & $NpmCmd start
        Write-Host
        Read-Host "Press Enter to continue" | Out-Null
    }
    "2" { 
        powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -NoExit -Command "& '$PSScriptRoot\portable-env.ps1' -Root '$Root' -Platform '$Platform'; Set-Location '$Root'; Write-Host 'Portable Hermes Agent shell'"
    }
    "0" { exit 0 }
    default { Write-Host "Invalid option" -ForegroundColor Yellow; Start-Sleep -Seconds 1 }
  }
}
