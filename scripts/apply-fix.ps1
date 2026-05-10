param(
  [string]$CodexHome = "$env:USERPROFILE\.codex",
  [string]$PluginVersion = "0.1.7",
  [switch]$Force,
  [switch]$SkipConfig
)

$ErrorActionPreference = "Stop"

function Backup-File {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    $backup = "$Path.before-codex-chrome-fix-$(Get-Date -Format yyyyMMdd-HHmmss)"
    Copy-Item -LiteralPath $Path -Destination $backup -Force
    Write-Host "Backup: $backup"
  }
}

function Replace-One {
  param(
    [string]$Content,
    [string]$Pattern,
    [scriptblock]$Replacement,
    [string]$Name
  )

  $regex = [regex]::new($Pattern)
  $matches = $regex.Matches($Content)
  if ($matches.Count -ne 1) {
    throw "Patch '$Name' expected exactly 1 match, found $($matches.Count). The installed plugin version may differ."
  }

  return $regex.Replace($Content, {
    param($m)
    & $Replacement $m
  }, 1)
}

function Set-TomlValue {
  param(
    [string]$Path,
    [string]$Section,
    [string]$Key,
    [string]$Value
  )

  if (!(Test-Path -LiteralPath $Path)) {
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
    Set-Content -LiteralPath $Path -Value "" -Encoding UTF8
  }

  $content = Get-Content -LiteralPath $Path -Raw
  $sectionPattern = "(?m)^\[$([regex]::Escape($Section))\]\s*$"
  $match = [regex]::Match($content, $sectionPattern)
  if (!$match.Success) {
    if ($content.Length -gt 0 -and !$content.EndsWith("`n")) { $content += "`n" }
    $content += "`n[$Section]`n$Key = $Value`n"
    Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
    return
  }

  $start = $match.Index + $match.Length
  $next = [regex]::Match($content.Substring($start), "(?m)^\[.+\]\s*$")
  $end = if ($next.Success) { $start + $next.Index } else { $content.Length }
  $body = $content.Substring($start, $end - $start)
  $keyPattern = "(?m)^$([regex]::Escape($Key))\s*=.*$"
  if ([regex]::IsMatch($body, $keyPattern)) {
    $body = [regex]::Replace($body, $keyPattern, "$Key = $Value")
  } else {
    if ($body.Length -gt 0 -and !$body.EndsWith("`n")) { $body += "`n" }
    $body += "$Key = $Value`n"
  }

  $content = $content.Substring(0, $start) + $body + $content.Substring($end)
  Set-Content -LiteralPath $Path -Value $content -Encoding UTF8
}

$PluginRoot = Join-Path $CodexHome "plugins\cache\openai-bundled\chrome\$PluginVersion"
$ClientSource = Join-Path $PluginRoot "scripts\browser-client.mjs"
$ClientTarget = Join-Path $PluginRoot "scripts\browser-client-net.mjs"
$SkillPath = Join-Path $PluginRoot "skills\chrome\SKILL.md"
$ConfigPath = Join-Path $CodexHome "config.toml"

if (!(Test-Path -LiteralPath $ClientSource)) {
  throw "Cannot find browser-client.mjs at: $ClientSource"
}
if (!(Test-Path -LiteralPath $SkillPath)) {
  throw "Cannot find Chrome SKILL.md at: $SkillPath"
}
if ((Test-Path -LiteralPath $ClientTarget) -and !$Force) {
  Write-Host "browser-client-net.mjs already exists. Use -Force to regenerate it."
} else {
  Write-Host "Generating browser-client-net.mjs..."
  Copy-Item -LiteralPath $ClientSource -Destination $ClientTarget -Force
  $content = Get-Content -LiteralPath $ClientTarget -Raw

  $content = Replace-One -Content $content `
    -Name "transport-create" `
    -Pattern 'static async create\((?<arg>[A-Za-z_$][\w$]*)\)\{let (?<bridge>[A-Za-z_$][\w$]*)=Wf\(\);if\(\k<bridge>!=null\)\{let (?<sock>[A-Za-z_$][\w$]*)=await \k<bridge>\.createConnection\(\k<arg>\);return new (?<ctor>[A-Za-z_$][\w$]*)\(\k<sock>\)\}throw new Error\(Vf\(\)\)\}' `
    -Replacement {
      param($m)
      $arg = $m.Groups["arg"].Value
      $ctor = $m.Groups["ctor"].Value
      return "static async create($arg){let{createConnection:r}=await import(""node:net""),n=r($arg);await new Promise((o,i)=>{let s=setTimeout(()=>{n.destroy(),i(new Error(""native pipe connect timed out""))},2e3);n.once(""connect"",()=>{clearTimeout(s),o()}),n.once(""error"",a=>{clearTimeout(s),i(a)})});return new $ctor(n)}"
    }

  $content = Replace-One -Content $content `
    -Name "setup-bridge-guard" `
    -Pattern 'async function nae\(\{globals:(?<globals>[A-Za-z_$][\w$]*)\}\)\{if\(Wf\(\)==null\)throw new Error\(Vf\(\)\);Ec\(\),Ly\(\);' `
    -Replacement {
      param($m)
      $globals = $m.Groups["globals"].Value
      return "async function nae({globals:$globals}){Ec(),Ly();"
    }

  $content = Replace-One -Content $content `
    -Name "ambient-startup" `
    -Pattern 'Ly=\(\)=>\{Ps\(\)\|\|\(jg\(\),Py\(\),rp\(\)\)\}' `
    -Replacement { param($m) "Ly=()=>{}" }

  $content = Replace-One -Content $content `
    -Name "analytics-event" `
    -Pattern 'var np=\((?<a>[A-Za-z_$][\w$]*),(?<b>[A-Za-z_$][\w$]*),(?<c>[A-Za-z_$][\w$]*)\)=>\{if\(!Ps\(\)\)return Dy\(vP\(\k<a>\),\k<b>,\k<c>\)\}' `
    -Replacement {
      param($m)
      return "var np=$($m.Groups["a"].Value),$($m.Groups["b"].Value),$($m.Groups["c"].Value)=>{}" -replace '^var np=', 'var np=(' -replace '=>', ')=>'
    }

  Set-Content -LiteralPath $ClientTarget -Value $content -Encoding UTF8
  Write-Host "Generated: $ClientTarget"
}

Write-Host "Updating Chrome skill note..."
Backup-File -Path $SkillPath
$skill = Get-Content -LiteralPath $SkillPath -Raw
if ($skill -notmatch 'browser-client-net\.mjs') {
  $note = @'
## Local Windows Fallback

On Windows, if `<plugin root>/scripts/browser-client-net.mjs` exists, import that file for Chrome tasks instead of `<plugin root>/scripts/browser-client.mjs`. It keeps the same `setupAtlasRuntime` API but uses a local named-pipe transport fallback.

'@
  $skill = $skill -replace '## Bootstrap\s*', "## Bootstrap`r`n`r`n$note"
}
$skill = $skill.Replace('<plugin root>/scripts/browser-client.mjs', '<chosen browser-client path>')
Set-Content -LiteralPath $SkillPath -Value $skill -Encoding UTF8
Write-Host "Updated: $SkillPath"

if (!$SkipConfig) {
  Write-Host "Updating Codex config..."
  Set-TomlValue -Path $ConfigPath -Section "features" -Key "plugins" -Value "true"
  Set-TomlValue -Path $ConfigPath -Section "features" -Key "apps" -Value "true"
  Set-TomlValue -Path $ConfigPath -Section 'plugins."chrome@openai-bundled"' -Key "enabled" -Value "true"
  Write-Host "Updated: $ConfigPath"
}

Write-Host ""
Write-Host "Done. Restart Codex, then run scripts\verify.ps1."

