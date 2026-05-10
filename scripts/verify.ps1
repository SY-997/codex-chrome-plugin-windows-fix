param(
  [string]$CodexHome = "$env:USERPROFILE\.codex",
  [string]$PluginVersion = "0.1.7"
)

$ErrorActionPreference = "Stop"

$Node = Join-Path $env:LOCALAPPDATA "OpenAI\Codex\bin\node.exe"
if (!(Test-Path -LiteralPath $Node)) {
  $Node = "node"
}

$PluginRoot = Join-Path $CodexHome "plugins\cache\openai-bundled\chrome\$PluginVersion"
$NetClient = Join-Path $PluginRoot "scripts\browser-client-net.mjs"
$NativeCheck = Join-Path $PluginRoot "scripts\check-native-host-manifest.js"
$ExtensionCheck = Join-Path $PluginRoot "scripts\check-extension-installed.js"

Write-Host "Codex home: $CodexHome"
Write-Host "Chrome plugin: $PluginRoot"
Write-Host "Node: $Node"
Write-Host ""

if (!(Test-Path -LiteralPath $PluginRoot)) {
  throw "Chrome plugin directory not found: $PluginRoot"
}
if (!(Test-Path -LiteralPath $NetClient)) {
  throw "Patched client not found: $NetClient"
}

Write-Host "Native Messaging Host check:"
& $Node $NativeCheck --json
Write-Host ""

Write-Host "Chrome Extension check:"
& $Node $ExtensionCheck --json
Write-Host ""

Write-Host "Verification scripts completed."
Write-Host "Final interactive test: ask Codex to use @chrome to open https://www.baidu.com/ and take a screenshot."

