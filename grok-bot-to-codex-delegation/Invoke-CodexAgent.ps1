#requires -Version 7.0
<#
.SYNOPSIS
Runs repository work with Codex GPT-5.6 Luna or Sol at high reasoning,
streaming JSONL events and a human live-status file.

.EXAMPLE
& "$env:SKILL_PACKAGE_ROOT\Invoke-CodexAgent.ps1" `
  -WorkingDirectory 'C:\path\to\repository' `
  -PromptFile (Join-Path $env:TEMP 'codex-task.txt')
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkingDirectory,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PromptFile,

    [Parameter()]
    [ValidateSet('Luna', 'Sol')]
    [string]$Model = 'Luna',

    [Parameter()]
    [switch]$UseSubagents
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-ExistingPath {
    param(
        [Parameter(Mandatory)][string]$LiteralPath,
        [Parameter(Mandatory)][string]$Label
    )

    try {
        return (Resolve-Path -LiteralPath $LiteralPath -ErrorAction Stop).Path
    }
    catch {
        throw "$Label does not exist or cannot be resolved: $LiteralPath"
    }
}

function Truncate-Text([string]$Text, [int]$Max = 240) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $flat = ($Text -replace '\s+', ' ').Trim()
    if ($flat.Length -le $Max) { return $flat }
    return $flat.Substring(0, $Max - 3) + '...'
}

function Get-Note($Obj, [string]$Name) {
    if ($null -eq $Obj) { return $null }
    $prop = $Obj.PSObject.Properties[$Name]
    if ($null -eq $prop) { return $null }
    return $prop.Value
}

$workingPath = Resolve-ExistingPath -LiteralPath $WorkingDirectory -Label 'Working directory'
$promptPath = Resolve-ExistingPath -LiteralPath $PromptFile -Label 'Prompt file'

if (-not (Test-Path -LiteralPath $workingPath -PathType Container)) {
    throw "Working directory is not a directory: $workingPath"
}
if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
    throw "Prompt file is not a file: $promptPath"
}

$gitCommand = Get-Command git -ErrorAction Stop | Select-Object -First 1
$repositoryRoot = (& $gitCommand.Source -C $workingPath rev-parse --show-toplevel 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) {
    throw "Working directory is not inside a Git repository: $workingPath`n$repositoryRoot"
}

$resolvedRepositoryRoot = Resolve-ExistingPath -LiteralPath $repositoryRoot -Label 'Git repository root'
$normalizedRepositoryRoot = [IO.Path]::GetFullPath($resolvedRepositoryRoot).TrimEnd('\', '/')

try {
    $strictUtf8 = [Text.UTF8Encoding]::new($false, $true)
    $prompt = [IO.File]::ReadAllText($promptPath, $strictUtf8)
}
catch {
    throw "Prompt file must be valid UTF-8: $promptPath. $($_.Exception.Message)"
}
if ([string]::IsNullOrWhiteSpace($prompt)) {
    throw "Prompt file is empty: $promptPath"
}

if ($UseSubagents) {
    $prompt = @"
Codex subagents are enabled and requested for this task. Use them for independent workstreams where they materially improve the result. Integrate and validate their work before reporting completion.

$prompt
"@
}

$codexCommand = Get-Command codex -ErrorAction Stop | Select-Object -First 1
$multiAgentFeatureFlag = if ($UseSubagents) { '--enable' } else { '--disable' }
$modelId = switch ($Model) {
    'Luna' { 'gpt-5.6-luna' }
    'Sol' { 'gpt-5.6-sol' }
}

$jsonlPath = Join-Path $normalizedRepositoryRoot '.tmp-codex-events.jsonl'
$livePath = Join-Path $normalizedRepositoryRoot '.tmp-codex-live.txt'
$nowPath = Join-Path $normalizedRepositoryRoot '.tmp-codex-now.txt'
$stampPath = Join-Path $normalizedRepositoryRoot '.tmp-codex-last-event'
$lastMessagePath = Join-Path $normalizedRepositoryRoot '.tmp-codex-last-message.txt'
$watchPath = Join-Path $normalizedRepositoryRoot '.tmp-codex-watch.json'

[IO.File]::WriteAllText($jsonlPath, '')
[IO.File]::WriteAllText($livePath, '')
[IO.File]::WriteAllText($stampPath, [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString())

$script:recent = [System.Collections.Generic.Queue[string]]::new()
$script:nowLine = 'starting Codex exec --json'

function Add-LiveLine([string]$Line) {
    $ts = Get-Date -Format 'HH:mm:ss'
    $entry = "$ts  $Line"
    $script:nowLine = $Line
    $script:recent.Enqueue($entry)
    while ($script:recent.Count -gt 24) { [void]$script:recent.Dequeue() }
    [IO.File]::AppendAllText($livePath, $entry + [Environment]::NewLine)
    [IO.File]::WriteAllText($stampPath, [DateTimeOffset]::UtcNow.ToUnixTimeSeconds().ToString())
    Write-Output $entry
}

function Write-WatchFile([string]$Status, [hashtable]$Extra = @{}) {
    $payload = [ordered]@{
        status = $Status
        repo = $normalizedRepositoryRoot
        contractPath = $promptPath
        model = $Model
        bridgePid = $PID
        updatedAt = (Get-Date).ToString('o')
    }
    foreach ($key in $Extra.Keys) { $payload[$key] = $Extra[$key] }
    if (Test-Path -LiteralPath $watchPath) {
        try {
            $existing = Get-Content -LiteralPath $watchPath -Raw -ErrorAction Stop | ConvertFrom-Json
            if ($existing.startedAt -and -not $payload.Contains('startedAt')) {
                $payload['startedAt'] = [string]$existing.startedAt
            }
        } catch { }
    }
    if (-not $payload.Contains('startedAt')) {
        $payload['startedAt'] = (Get-Date).ToString('o')
    }
    ($payload | ConvertTo-Json -Depth 5) | Set-Content -LiteralPath $watchPath -Encoding utf8
}

function Notify-CodexFinishedWebhook {
    param(
        [Parameter(Mandatory)][string]$Status,
        [Parameter(Mandatory)][bool]$LastMessagePresent
    )
    $configPath = Join-Path $PSScriptRoot 'codex-finish-webhook.json'
    if (-not (Test-Path -LiteralPath $configPath)) {
        Add-LiveLine 'webhook skip  missing codex-finish-webhook.json'
        return
    }
    try {
        $cfg = Get-Content -LiteralPath $configPath -Raw -ErrorAction Stop | ConvertFrom-Json
    } catch {
        Add-LiveLine ("webhook skip  invalid config: " + $_.Exception.Message)
        return
    }
    $url = [string]$cfg.url
    if ([string]::IsNullOrWhiteSpace($url) -or $url -match 'PASTE_') {
        Add-LiveLine 'webhook skip  placeholder or empty url'
        return
    }
    $headers = @{}
    if ($cfg.PSObject.Properties.Name -contains 'senderKey' -and $cfg.senderKey) {
        $headers['Authorization'] = "Bearer $([string]$cfg.senderKey)"
    }
    if ($cfg.PSObject.Properties.Name -contains 'headerName' -and $cfg.headerName -and $cfg.headerValue) {
        $headers[[string]$cfg.headerName] = [string]$cfg.headerValue
    }
    $bodyObj = [ordered]@{
        event = 'codex.session_ended'
        status = $Status
        repo = $normalizedRepositoryRoot
        contractPath = $promptPath
        model = $Model
        bridgePid = $PID
        lastMessagePresent = $LastMessagePresent
        finishedAt = (Get-Date).ToString('o')
        watchPath = $watchPath
        lastMessagePath = $lastMessagePath
        nowPath = $nowPath
    }
    $json = ($bodyObj | ConvertTo-Json -Depth 5 -Compress)
    try {
        Invoke-RestMethod -Method Post -Uri $url -Body $json -ContentType 'application/json; charset=utf-8' -Headers $headers -TimeoutSec 30 | Out-Null
        Add-LiveLine 'webhook ok  finish notified'
    } catch {
        $msg = ($_.Exception.Message -replace '\s+', ' ').Trim()
        if ($msg.Length -gt 200) { $msg = $msg.Substring(0, 197) + '...' }
        Add-LiveLine ("webhook FAIL  " + $msg)
    }
}

function Write-NowFile {
    $last = 0L
    if (Test-Path -LiteralPath $stampPath) {
        [void][int64]::TryParse(([IO.File]::ReadAllText($stampPath).Trim()), [ref]$last)
    }
    $age = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $last
    $health = if ($age -ge 180) { "STALL_CANDIDATE" } else { "healthy" }
    $recentText = ($script:recent.ToArray() | Select-Object -Last 16) -join [Environment]::NewLine
    $body = @"
CODEX NOW
updated: $(Get-Date -Format 'HH:mm:ss')
model: $Model
health: $health
seconds_since_event: $age
now: $script:nowLine

RECENT
$recentText

files:
  live: $livePath
  jsonl: $jsonlPath
  last_message: $lastMessagePath
"@
    [IO.File]::WriteAllText($nowPath, $body)
}

Add-LiveLine "session start  model=$Model  jsonl on  reasoning=concise"
Write-WatchFile 'in_progress'
Write-NowFile

$heartbeat = Start-ThreadJob -Name 'codex-live-heartbeat' -ArgumentList $nowPath, $stampPath, $livePath {
    param($nowPath, $stampPath, $livePath)
    while ($true) {
        Start-Sleep -Seconds 10
        $last = 0L
        if (Test-Path -LiteralPath $stampPath) {
            [void][int64]::TryParse(([IO.File]::ReadAllText($stampPath).Trim()), [ref]$last)
        }
        $age = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds() - $last
        $health = if ($age -ge 180) { "STALL_CANDIDATE" } else { "healthy" }
        $tail = ''
        if (Test-Path -LiteralPath $livePath) {
            $lines = Get-Content -LiteralPath $livePath -Tail 16 -ErrorAction SilentlyContinue
            if ($lines) { $tail = $lines -join [Environment]::NewLine }
        }
        $nowLine = 'waiting on model'
        if ($tail) {
            $lastLine = ($tail -split "`n")[-1]
            if ($lastLine -match '^\d{2}:\d{2}:\d{2}\s+(.*)$') { $nowLine = $Matches[1] }
        }
        $body = @"
CODEX NOW
updated: $(Get-Date -Format 'HH:mm:ss')
health: $health
seconds_since_event: $age
now: $nowLine

RECENT
$tail
"@
        [IO.File]::WriteAllText($nowPath, $body)
    }
}

$codexArguments = @(
    'exec'
    '--dangerously-bypass-approvals-and-sandbox'
    $multiAgentFeatureFlag, 'multi_agent'
    '--model', $modelId
    '--json'
    '--output-last-message', $lastMessagePath
    '--config', 'model_reasoning_effort="high"'
    '--config', 'model_reasoning_summary="concise"'
    '--config', 'hide_agent_reasoning=false'
    '--config', 'service_tier="fast"'
    '--color', 'never'
    '--cd', $normalizedRepositoryRoot
    '-'
)

try {
    $prompt | & $codexCommand.Source @codexArguments 2>&1 | ForEach-Object {
        try {
        $raw = "$_"
        if ([string]::IsNullOrWhiteSpace($raw)) { return }
        if ($raw.TrimStart().StartsWith('{')) {
            [IO.File]::AppendAllText($jsonlPath, $raw + [Environment]::NewLine)
            try {
                $evt = $raw | ConvertFrom-Json
            }
            catch {
                Add-LiveLine "json-parse  $raw"
                Write-NowFile
                return
            }
            $type = [string](Get-Note $evt 'type')
            $item = Get-Note $evt 'item'
            $usage = Get-Note $evt 'usage'
            $line = $null
            switch ($type) {
                'thread.started' { $line = "thread $(Get-Note $evt 'thread_id')" }
                'turn.started' { $line = 'turn started' }
                'turn.completed' { $line = "turn completed  in=$(Get-Note $usage 'input_tokens') out=$(Get-Note $usage 'output_tokens')" }
                'turn.failed' { $line = "turn FAILED  $(Truncate-Text ((Get-Note $evt 'error') | Out-String))" }
                'error' { $line = "error  $(Truncate-Text (Get-Note $evt 'message'))" }
                'item.started' {
                    switch ([string]$item.type) {
                        'command_execution' { $line = "exec start  $(Truncate-Text $item.command 200)" }
                        'agent_message' { $line = "agent..." }
                        'reasoning' { $line = "thinking..." }
                        'mcp_tool_call' { $line = "mcp  $($item.server)/$($item.tool)" }
                        'web_search' { $line = "web search  $(Truncate-Text $item.query)" }
                        'todo_list' { $line = 'plan update' }
                        default { $line = "start $($item.type)" }
                    }
                }
                'item.updated' {
                    if ([string]$item.type -eq 'todo_list') { $line = 'plan updated' }
                    elseif ([string]$item.type -eq 'agent_message') { $line = "agent  $(Truncate-Text $item.text)" }
                    elseif ([string]$item.type -eq 'reasoning') { $line = "think  $(Truncate-Text $item.text)" }
                }
                'item.completed' {
                    switch ([string]$item.type) {
                        'agent_message' { $line = "AGENT  $(Truncate-Text $item.text 400)" }
                        'reasoning' { $line = "THINK  $(Truncate-Text $item.text 400)" }
                        'command_execution' { $line = "exec done  $(Truncate-Text $item.command 160)" }
                        'file_change' {
                            $names = @()
                            if ($item.changes) {
                                foreach ($c in $item.changes) {
                                    $names += "$( $c.kind ) $( $c.path )"
                                }
                            }
                            $line = "files  $(Truncate-Text (($names -join ', ') ))"
                        }
                        'mcp_tool_call' { $line = "mcp done  $($item.server)/$($item.tool)" }
                        'web_search' { $line = "web done  $(Truncate-Text $item.query)" }
                        'todo_list' { $line = 'plan completed' }
                        'error' { $line = "item error  $(Truncate-Text $item.message)" }
                        default { $line = "done $($item.type)" }
                    }
                }
                default { $line = $type }
            }
            if ($line) {
                Add-LiveLine $line
                Write-NowFile
            }
        }
        else {
            Add-LiveLine (Truncate-Text $raw 300)
            Write-NowFile
        }
        } catch {
            Add-LiveLine "event-error  $($_.Exception.Message)"
            Write-NowFile
        }
    }
}
finally {
    Stop-Job $heartbeat -ErrorAction SilentlyContinue
    Remove-Job $heartbeat -Force -ErrorAction SilentlyContinue
    $finishedAt = (Get-Date).ToString('o')
    $hasLast = (Test-Path -LiteralPath $lastMessagePath) -and ((Get-Item -LiteralPath $lastMessagePath).Length -gt 0)
    $endStatus = if ($hasLast) { 'session_ended' } else { 'session_ended_no_message' }
    Write-WatchFile $endStatus @{
        finishedAt = $finishedAt
        lastMessagePresent = $hasLast
    }
    Notify-CodexFinishedWebhook -Status $endStatus -LastMessagePresent ([bool]$hasLast)
    Add-LiveLine 'session end'
    Write-NowFile
}

$exitCode = if ($null -eq $LASTEXITCODE) { 1 } else { [int]$LASTEXITCODE }
exit $exitCode
