#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][uri]$Url,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$SenderKey,
    [string]$OutPath = (Join-Path $PSScriptRoot 'opencode-finish-webhook.json')
)
$ErrorActionPreference = 'Stop'
if (-not $Url.IsAbsoluteUri -or ($Url.Scheme -ne 'https' -and -not ($Url.Scheme -eq 'http' -and $Url.IsLoopback))) {
    throw 'URL must use HTTPS, or HTTP on loopback for local verification.'
}
[ordered]@{ url = $Url.AbsoluteUri; senderKey = $SenderKey } | ConvertTo-Json | Set-Content -LiteralPath $OutPath -Encoding utf8
Write-Output "Wrote $OutPath"
