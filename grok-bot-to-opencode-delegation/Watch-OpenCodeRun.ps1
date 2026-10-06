#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WatchPath,
    [string]$InvokeScript = $(Join-Path $env:SKILL_PACKAGE_ROOT 'Invoke-OpenCodeAgent.ps1'),
    [int]$StallMinutes = 12,
    [switch]$AllowRestart,
    [int]$MaxRestarts = 1
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $WatchPath)) {
    [ordered]@{ status = 'missing_watch'; watchPath = $WatchPath; action = 'none' } | ConvertTo-Json -Compress
    exit 2
}

$watch = Get-Content -LiteralPath $WatchPath -Raw | ConvertFrom-Json
$runDirectory = [string]$watch.runDirectory
if (-not $runDirectory) { $runDirectory = Split-Path -Parent $WatchPath }
$statePath = Join-Path $runDirectory 'watchdog-state.json'
$state = [ordered]@{ restarts = 0; lastAction = $null; lastCheckedAt = $null }
if (Test-Path -LiteralPath $statePath) {
    $existing = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($null -ne $existing.restarts) { $state.restarts = [int]$existing.restarts }
}

function Save-State {
    $state.lastCheckedAt = [DateTimeOffset]::UtcNow.ToString('o')
    [IO.File]::WriteAllText($statePath, ($state | ConvertTo-Json -Depth 6))
}

$bridgePid = $watch.bridgePid
$workerPid = $watch.workerPid
$status = [string]$watch.status
$updatedAt = $null
if ($watch.updatedAt) { $updatedAt = [DateTimeOffset]::Parse([string]$watch.updatedAt) }

$bridgeAlive = $false
$workerAlive = $false
if ($bridgePid) {
    try { $bridgeAlive = $null -ne (Get-Process -Id ([int]$bridgePid) -ErrorAction Stop) } catch { $bridgeAlive = $false }
}
if ($workerPid) {
    try { $workerAlive = $null -ne (Get-Process -Id ([int]$workerPid) -ErrorAction Stop) } catch { $workerAlive = $false }
}

$result = [ordered]@{
    status = $status
    watchPath = $WatchPath
    runDirectory = $runDirectory
    bridgePid = $bridgePid
    workerPid = $workerPid
    bridgeAlive = $bridgeAlive
    workerAlive = $workerAlive
    action = 'none'
    healthy = $false
    reason = $null
    restarts = [int]$state.restarts
}

if ($status -in @('completed', 'failed')) {
    $result.healthy = $true
    $result.reason = "terminal:$status"
    Save-State
    $result | ConvertTo-Json -Compress
    exit $(if ($status -eq 'completed') { 0 } else { 1 })
}

if ($status -in @('starting', 'running') -and ($bridgeAlive -or $workerAlive)) {
    if ($updatedAt -and (([DateTimeOffset]::UtcNow - $updatedAt).TotalMinutes -gt $StallMinutes)) {
        $result.healthy = $false
        $result.reason = "stalled_no_update_${StallMinutes}m"
    } else {
        $result.healthy = $true
        $result.reason = 'process_alive'
        Save-State
        $result | ConvertTo-Json -Compress
        exit 0
    }
} else {
    $result.healthy = $false
    $result.reason = "nonterminal_without_process:$status"
}

if (-not $AllowRestart -or [int]$state.restarts -ge $MaxRestarts) {
    $result.action = 'needs_manual'
    Save-State
    $result | ConvertTo-Json -Compress
    exit 3
}

# Restart only with the same contract/model captured in watch.json when present.
$contractPath = [string]$watch.contractPath
$model = [string]$watch.model
$sessionId = [string]$watch.sessionId
if (-not $contractPath -or -not (Test-Path -LiteralPath $contractPath)) {
    $result.action = 'restart_blocked_missing_contract'
    Save-State
    $result | ConvertTo-Json -Compress
    exit 4
}

$restartRun = Join-Path ([IO.Path]::GetTempPath()) ('opencode-delegation-restart-' + [guid]::NewGuid().ToString('N'))
$args = @(
    '-NoProfile', '-File', $InvokeScript,
    '-WorkingDirectory', [string]$watch.repo,
    '-PromptFile', $contractPath,
    '-RunDirectory', $restartRun,
    '-Background'
)
if ($model) { $args += @('-Model', $model) }
if ($sessionId) { $args += @('-SessionId', $sessionId) }
$webhookConfig = Join-Path (Split-Path -Parent $InvokeScript) 'opencode-finish-webhook.json'
if (Test-Path -LiteralPath $webhookConfig) { $args += @('-WebhookConfig', $webhookConfig) }

$launch = & pwsh @args | Out-String
$state.restarts = [int]$state.restarts + 1
$state.lastAction = 'auto_restart'
Save-State
$result.action = 'auto_restart'
$result.restarts = [int]$state.restarts
$result.restartLaunch = $launch.Trim()
$result.restartRunDirectory = $restartRun
$result | ConvertTo-Json -Compress -Depth 8
exit 10
