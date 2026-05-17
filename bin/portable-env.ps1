param(
  [Parameter(Mandatory = $true)]
  [string]$Root,
  [string]$Platform = "windows-x64"
)

$Root = [System.IO.Path]::GetFullPath($Root)
$PackageRoot = Join-Path $Root "packages\$Platform"
$NpmPrefix = Join-Path $PackageRoot "npm-global"
$NpmCache = Join-Path $PackageRoot "npm-cache"
$NodeRoot = Join-Path $Root "runtime\$Platform"

$env:HERMES_AGENT_PORTABLE_ROOT = $Root
$env:HERMES_AGENT_PORTABLE_PLATFORM = $Platform
$env:HERMES_AGENT_HOME = Join-Path $Root "data\home"
$env:HERMES_AGENT_STATE_DIR = Join-Path $Root "data\state"
$env:HERMES_AGENT_CONFIG_PATH = Join-Path $Root "data\config\hermes-agent.json"
$env:HERMES_AGENT_PORTABLE_WORKSPACE = Join-Path $Root "data\workspace"

$env:HOME = $env:HERMES_AGENT_HOME
$env:USERPROFILE = $env:HERMES_AGENT_HOME
$env:APPDATA = Join-Path $env:HERMES_AGENT_HOME "AppData\Roaming"
$env:LOCALAPPDATA = Join-Path $env:HERMES_AGENT_HOME "AppData\Local"

$env:TEMP = Join-Path $Root "data\temp"
$env:TMP = $env:TEMP
$env:npm_config_prefix = $NpmPrefix
$env:npm_config_cache = $NpmCache
$env:npm_config_update_notifier = "false"
$env:npm_config_fund = "false"
$env:npm_config_audit = "false"
$env:PATH = "$NodeRoot;$NpmPrefix;$env:PATH"

foreach ($dir in @(
  $env:HERMES_AGENT_HOME,
  $env:HERMES_AGENT_STATE_DIR,
  (Split-Path -Parent $env:HERMES_AGENT_CONFIG_PATH),
  $env:HERMES_AGENT_PORTABLE_WORKSPACE,
  $env:APPDATA,
  $env:LOCALAPPDATA,
  $env:TEMP,
  $NpmPrefix,
  $NpmCache,
  (Join-Path $Root "runtime\downloads"),
  (Join-Path $Root "logs")
)) {
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

function Write-Utf8NoBom([string]$Path, [string]$Value) {
  $encoding = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Value, $encoding)
}

function New-PortableConfig {
  $template = Join-Path $Root "templates\hermes-agent.portable.json"
  if (Test-Path -LiteralPath $template) {
    $configText = Get-Content -LiteralPath $template -Raw
    Write-Utf8NoBom -Path $env:HERMES_AGENT_CONFIG_PATH -Value $configText
  } else {
    Write-Utf8NoBom -Path $env:HERMES_AGENT_CONFIG_PATH -Value "{}"
  }
}

if (-not (Test-Path -LiteralPath $env:HERMES_AGENT_CONFIG_PATH)) {
  New-PortableConfig
}
