#requires -Version 7.0
<#
.SYNOPSIS
Ensures codex-finish-webhook.json exists for Invoke-CodexAgent finish notify.
Grok Bot runs this; do not ask the user to hand-edit the file.

.DESCRIPTION
If -Url and -SenderKey are passed, writes the config.
If missing args, opens the Grok Bot deep links for the codex-bridge-finished routine
so credentials can be copied, then if clipboard looks like a URL/key after a short wait,
assembles the file. Prefer bot-supplied -Url/-SenderKey.
#>
param(
  [string]$Url,
  [string]$SenderKey,
  [string]$OutPath = (Join-Path $PSScriptRoot 'codex-finish-webhook.json'),
  [switch]$OpenDeepLinks
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Config([string]$u, [string]$k) {
  if ([string]::IsNullOrWhiteSpace($u) -or [string]::IsNullOrWhiteSpace($k)) {
    throw 'Url and SenderKey are required to write codex-finish-webhook.json'
  }
  if ($u -notmatch '^https://') { throw "Url must be https: $u" }
  $payload = [ordered]@{ url = $u.Trim(); senderKey = $k.Trim() }
  ($payload | ConvertTo-Json -Depth 3) | Set-Content -LiteralPath $OutPath -Encoding utf8
  Write-Output "wrote $OutPath"
}

if ($Url -and $SenderKey) {
  Write-Config -u $Url -k $SenderKey
  exit 0
}

if (Test-Path -LiteralPath $OutPath) {
  try {
    $cfg = Get-Content -LiteralPath $OutPath -Raw | ConvertFrom-Json
    if ($cfg.url -and $cfg.senderKey -and $cfg.url -match '^https://' -and $cfg.senderKey -notmatch 'YOUR_|PLACEHOLDER|paste') {
      Write-Output "already configured: $OutPath"
      exit 0
    }
  } catch {}
}

if ($OpenDeepLinks) {
  Start-Process 'grokbot://app/v1/sidebar?target=webhook-url&automation=codex-bridge-finished'
  Start-Sleep -Seconds 1
  Start-Process 'grokbot://app/v1/sidebar?target=webhook-key&automation=codex-bridge-finished'
  Write-Output 'opened deep links; bot must supply -Url and -SenderKey on a follow-up run'
  exit 2
}

Write-Output 'missing url/senderKey; pass -Url and -SenderKey or -OpenDeepLinks'
exit 3
