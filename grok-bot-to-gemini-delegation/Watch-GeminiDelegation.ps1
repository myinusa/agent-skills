#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$PromptFile,
    [string]$Model = 'gemini-3.7-flash-high',
    [int]$TimeoutSeconds = 1800,
    [int]$StallSeconds = 90,
    [int]$MaxRestarts = 4,
    [string]$StatusFile,
    [string]$RunPtrFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = (Resolve-Path -LiteralPath $WorkingDirectory).Path
$prompt = (Resolve-Path -LiteralPath $PromptFile).Path
$bridge = Join-Path $PSScriptRoot 'Invoke-GeminiAgent.ps1'
if (-not (Test-Path -LiteralPath $bridge)) { throw "Missing bridge: $bridge" }
if (-not $StatusFile) { $StatusFile = Join-Path $repo '.grok\gemini-watchdog-status.txt' }
if (-not $RunPtrFile) { $RunPtrFile = Join-Path $repo '.grok\gemini-latest-run.txt' }
New-Item -ItemType Directory -Force -Path (Split-Path $StatusFile) | Out-Null

function Write-Status([string]$Message) {
    $line = '{0:o} {1}' -f [DateTimeOffset]::Now, $Message
    [IO.File]::AppendAllText($StatusFile, $line + [Environment]::NewLine)
    Write-Output $line
}

function Write-Attention([string]$State, [string]$Detail) {
    $attentionPath = Join-Path (Split-Path $StatusFile) 'gemini-attention.json'
    $payload = [ordered]@{
        state = $State
        detail = $Detail
        model = $Model
        runDir = $runDir
        promptFile = $prompt
        repo = $repo
        updatedAt = [DateTimeOffset]::Now.ToString('o')
        needsUserPing = $true
        needsBrowserReview = ($State -eq 'success')
    } | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($attentionPath, $payload, [Text.UTF8Encoding]::new($false))
    Write-Status "ATTENTION $State $Detail"
}

function Get-AgyPids {
    @(Get-Process -Name agy -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
}

$attempt = 0
$finalExit = 1
$runDir = $null
Write-Status "Watchdog start model=$Model stall=${StallSeconds}s maxRestarts=$MaxRestarts"

while ($attempt -le $MaxRestarts) {
    $attempt++
    Write-Status "Attempt $attempt/$($MaxRestarts+1) launching bridge"
    $stdoutLog = Join-Path $env:TEMP ('grok-gemini-watchdog-stdout-' + [guid]::NewGuid().ToString('N') + '.txt')
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'pwsh'
    $psi.ArgumentList.Add('-NoProfile')
    $psi.ArgumentList.Add('-File')
    $psi.ArgumentList.Add($bridge)
    $psi.ArgumentList.Add('-WorkingDirectory')
    $psi.ArgumentList.Add($repo)
    $psi.ArgumentList.Add('-PromptFile')
    $psi.ArgumentList.Add($prompt)
    $psi.ArgumentList.Add('-Model')
    $psi.ArgumentList.Add($Model)
    $psi.ArgumentList.Add('-TimeoutSeconds')
    $psi.ArgumentList.Add("$TimeoutSeconds")
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $p = [Diagnostics.Process]::Start($psi)

    $runDir = $null
    $lastLiveLen = -1
    $lastProgress = [DateTime]::UtcNow
    $reader = $p.StandardOutput
    $errReader = $p.StandardError
    '' | Set-Content -LiteralPath $stdoutLog

    while (-not $p.HasExited) {
        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            Add-Content -LiteralPath $stdoutLog -Value $line
            if ($line -match '^Run directory:\s*(.+)$') {
                $runDir = $Matches[1].Trim()
                Set-Content -LiteralPath $RunPtrFile -Value $runDir -Encoding UTF8
                Write-Status "RunDir $runDir"
            }
            if ($line -match 'Result:|EXIT=|HAS_RESPONSE') {
                $lastProgress = [DateTime]::UtcNow
            }
        }
        while (-not $errReader.EndOfStream) {
            Add-Content -LiteralPath $stdoutLog -Value ('ERR ' + $errReader.ReadLine())
        }

        if ($runDir) {
            $live = Join-Path $runDir 'live.txt'
            $events = Join-Path $runDir 'events.jsonl'
            $progressPath = if (Test-Path $events) { $events } elseif (Test-Path $live) { $live } else { $null }
            if ($progressPath) {
                $len = (Get-Item -LiteralPath $progressPath).Length
                if ($len -ne $lastLiveLen) {
                    $lastLiveLen = $len
                    $lastProgress = [DateTime]::UtcNow
                }
            }
            if (Test-Path (Join-Path $runDir 'response.txt')) {
                $lastProgress = [DateTime]::UtcNow
            }
        }

        $idle = ([DateTime]::UtcNow - $lastProgress).TotalSeconds
        if ($idle -ge $StallSeconds) {
            Write-Status "STALL detected idle=${idle:N0}s — killing agy/bridge attempt $attempt"
            Write-Attention 'stall' "STALL attempt $attempt idle=${idle:N0}s"
            Get-AgyPids | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue }
            if (-not $p.HasExited) {
                try { $p.Kill($true) } catch { try { $p.Kill() } catch {} }
            }
            Start-Sleep -Seconds 2
            break
        }
        Start-Sleep -Milliseconds 1000
    }

    while (-not $reader.EndOfStream) { Add-Content -LiteralPath $stdoutLog -Value $reader.ReadLine() }
    if (-not $runDir -and (Test-Path $RunPtrFile)) { $runDir = (Get-Content $RunPtrFile | Select-Object -First 1) }

    $success = $false
    if ($runDir -and (Test-Path (Join-Path $runDir 'result.json'))) {
        try {
            $rj = Get-Content (Join-Path $runDir 'result.json') -Raw | ConvertFrom-Json
            if ($rj.status -eq 'SUCCESS' -and (Test-Path (Join-Path $runDir 'response.txt')) -and ((Get-Item (Join-Path $runDir 'response.txt')).Length -gt 0)) {
                $success = $true
                $finalExit = 0
            }
            Write-Status "Attempt $attempt provider status=$($rj.status) exit=$($p.ExitCode)"
        } catch {
            Write-Status "Attempt $attempt result parse failed: $($_.Exception.Message)"
        }
    } else {
        Write-Status "Attempt $attempt ended without result.json exit=$($p.ExitCode)"
    }

    if ($success) {
        Write-Status 'COMPLETED SUCCESS'
        Write-Attention 'success' 'Gemini pass completed; Grok must review and notify'
        Set-Content -LiteralPath (Join-Path (Split-Path $StatusFile) 'gemini-watchdog-state.txt') -Value 'success' -Encoding UTF8
        exit 0
    }

    if ($attempt -gt $MaxRestarts) { break }

    $nudge = Join-Path $env:TEMP ('grok-gemini-stall-nudge-' + [guid]::NewGuid().ToString('N') + '.txt')
    $orig = [IO.File]::ReadAllText($prompt)
    $extra = @"

## Stall recovery note from watchdog
Previous attempt stalled or failed without SUCCESS. Continue the SAME contract. Do not restart finished work. Prefer remaining unfinished consumers. If a tool hangs, skip that approach and use a different file/read strategy. One clean edit per issue; max two replaces per file then move on.
"@
    [IO.File]::WriteAllText($nudge, $orig + $extra, [Text.UTF8Encoding]::new($false))
    $prompt = $nudge
    Write-Status "Prepared stall-nudge prompt for retry: $nudge"
    Start-Sleep -Seconds 3
}

Write-Status "FAILED after $attempt attempts"
Write-Attention 'failed' "FAILED after $attempt attempts"
Set-Content -LiteralPath (Join-Path (Split-Path $StatusFile) 'gemini-watchdog-state.txt') -Value 'failed' -Encoding UTF8
exit $finalExit