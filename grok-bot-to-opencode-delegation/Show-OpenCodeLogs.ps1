#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RunDirectory,
    [ValidateSet('live','events','stderr','watch','last')][string]$Which = 'live',
    [int]$Lines = 40
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$map = @{
    live = 'live.txt'
    events = 'events.jsonl'
    stderr = 'stderr.txt'
    watch = 'watch.json'
    last = 'last-message.txt'
}
$path = Join-Path $RunDirectory $map[$Which]
if (-not (Test-Path -LiteralPath $path)) { throw "Missing $path" }
if ($Which -eq 'watch') {
    Get-Content -LiteralPath $path -Raw
} else {
    Get-Content -LiteralPath $path -Tail $Lines
}
