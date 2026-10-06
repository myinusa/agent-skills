#requires -Version 7.0
<#
.SYNOPSIS
Runs one Gemini repository task through authenticated Antigravity, with live progress and retained results.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$WorkingDirectory,
    [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$PromptFile,
    [ValidatePattern('^gemini-[a-z0-9.-]+$')]
    [string]$Model = 'gemini-3.7-flash',
    [switch]$UseSubagents,
    [ValidateRange(1, 2147483647)][int]$TimeoutSeconds = 600
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

$workingPath = (Resolve-Path -LiteralPath $WorkingDirectory).Path
$promptPath = (Resolve-Path -LiteralPath $PromptFile).Path
if (-not (Test-Path -LiteralPath $workingPath -PathType Container)) {
    throw "WorkingDirectory must be a directory: $workingPath"
}
$prompt = [IO.File]::ReadAllText($promptPath, [Text.UTF8Encoding]::new($false, $true))
if ([string]::IsNullOrWhiteSpace($prompt)) { throw "Prompt file is empty: $promptPath" }

$git = (Get-Command git -CommandType Application | Select-Object -First 1).Source
$repositoryRoot = (& $git -C $workingPath rev-parse --show-toplevel 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0) { throw "Unable to resolve Git repository: $repositoryRoot" }
$repositoryRoot = (Resolve-Path -LiteralPath $repositoryRoot).Path
$agy = (Get-Command agy -CommandType Application | Select-Object -First 1).Source
$modelSlug = switch ($Model) {
    'gemini-3.7-flash' { 'gemini-3.7-flash-medium' }
    'gemini-3.7-flash-high' { 'gemini-3.7-flash-high' }
    'gemini-3.1-pro' { 'gemini-3.1-pro-high' }
    default { $Model }
}
$models = (& $agy models 2>&1 | Out-String)
if ($LASTEXITCODE -ne 0) { throw "agy models failed: $models" }
if ($models -notmatch ('(?<![\w.-])' + [regex]::Escape($modelSlug) + '(?![\w.-])')) {
    throw "Requested model '$modelSlug' is unavailable. agy models returned:`n$models"
}

$runDirectory = Join-Path ([IO.Path]::GetTempPath()) ('grok-gemini-' + [guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($runDirectory)
$eventsPath = Join-Path $runDirectory 'events.jsonl'
$livePath = Join-Path $runDirectory 'live.txt'
$resultPath = Join-Path $runDirectory 'result.json'
$responsePath = Join-Path $runDirectory 'response.txt'

function Format-ToolProgress([string]$ToolName, $ToolInfo) {
    if (-not $ToolInfo) { return $ToolName }
    $params = $null
    if ($ToolInfo -is [hashtable]) {
        if ($ToolInfo.ContainsKey('parameters')) { $params = $ToolInfo['parameters'] }
    } else {
        try { $params = $ToolInfo.parameters } catch { }
    }
    if (-not $params) { return $ToolName }
    $bits = New-Object System.Collections.Generic.List[string]
    $bits.Add($ToolName)
    $get = {
        param($obj, $name)
        if ($obj -is [hashtable]) {
            if ($obj.ContainsKey($name)) { return [string]$obj[$name] }
            return $null
        }
        try { return [string]$obj.$name } catch { return $null }
    }
    foreach ($k in @('TargetFile','AbsolutePath','SearchPath','path','Path','file_path')) {
        $v = & $get $params $k
        if ($v) {
            $root = $repositoryRoot + [IO.Path]::DirectorySeparatorChar
            if ($v.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
                $v = $v.Substring($root.Length).Replace('\','/')
            }
            $bits.Add($v)
            break
        }
    }
    foreach ($k in @('Query','Pattern','Name','Command','Instruction')) {
        $v = & $get $params $k
        if ($v) {
            $v = ($v -replace '\s+', ' ')
            if ($v.Length -gt 120) { $v = $v.Substring(0,120) + '…' }
            $bits.Add("$k=$v")
            break
        }
    }
    return ($bits -join ' ')
}
function Write-ProgressLine([string]$Message) {
    $line = '{0:o} {1}' -f [DateTimeOffset]::Now, $Message
    [IO.File]::AppendAllText($livePath, $line + [Environment]::NewLine)
    Write-Output $line
}

$agentInstructions = if ($UseSubagents) {
    "Gemini subagents are requested. Use Antigravity's native subagents for useful independent work, carrying the contract scope and repository rules into each assignment. Keep every subagent on $modelSlug. Integrate their results and wait for all delegated work to finish before returning. Report unavailable subagent capabilities or model selection as unresolved. Grok retains final acceptance."
} else {
    'Work as one agent. Keep delegation and final acceptance with Grok.'
}
$workerPrompt = @"
You are the Gemini repository worker. Grok owns orchestration, review, and acceptance.
Read applicable repository AGENTS.md and its referenced rules before working; also honor applicable Antigravity rules.
Execute the contract within its authorized scope, preserving unrelated user changes.
$agentInstructions
Commits, merges, rebases, pushes, releases, and deployments require explicit authorization in the contract.
Return summary, changed_files, validation, risks, and unresolved. Report actual command outcomes and remaining gaps.

$prompt
"@
$message = @{ event = 'user'; message = @{ content = $workerPrompt } } | ConvertTo-Json -Compress -Depth 5
$agyArguments = @(
    '--dangerously-skip-permissions', '--disable-slash-commands',
    '--add-dir', $repositoryRoot, '--model', $modelSlug,
    '--print-timeout', "${TimeoutSeconds}s", '--input-format', 'stream-json', '--output-format', 'stream-json'
)

$result = $null
$exitCode = 1
Write-Output "Run directory: $runDirectory"
Write-ProgressLine "Starting $modelSlug in $repositoryRoot"
Push-Location -LiteralPath $repositoryRoot
try {
    $message | & $agy @agyArguments 2>&1 | ForEach-Object {
        $line = [string]$_
        if ([string]::IsNullOrWhiteSpace($line)) { return }
        if (-not $line.TrimStart().StartsWith('{')) {
            Write-ProgressLine $line
            return
        }
        [IO.File]::AppendAllText($eventsPath, $line + [Environment]::NewLine)
        $event = ConvertFrom-Json -InputObject $line -AsHashtable
        switch ($event.event) {
            'init' { Write-ProgressLine "Session $($event.conversation_id)" }
            'step_update' {
                $step = $event.step_update
                if ($step['subagent_info']) {
                    foreach ($child in $step['subagent_info']['subagents']) {
                        Write-ProgressLine "$($step.state) subagent dispatch: $($child.role) [$($child.conversation_id)]"
                    }
                }
                elseif ($step.step_type -eq 'tool') {
                    $toolInfo = $step['tool_info']
                    $detail = Format-ToolProgress $step.tool_name $toolInfo
                    Write-ProgressLine "$($step.state) $detail"
                    if ($toolInfo -and $toolInfo['error']) {
                        Write-ProgressLine ([string]$toolInfo['error']['message'])
                    }
                }
                elseif ($step['text_delta']) {
                    Write-ProgressLine ([string]$step['text_delta'])
                }
            }
            'result' {
                $result = $event.result
                [IO.File]::WriteAllText($resultPath, ($result | ConvertTo-Json -Depth 50))
                [IO.File]::WriteAllText($responsePath, [string]$result['response'])
                Write-ProgressLine "Result: $($result.status)"
                Write-Output ([string]$result['response'])
                if ($result['error']) { Write-ProgressLine ([string]$result['error']) }
            }
        }
    }
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}
if ($exitCode -ne 0) {
    Write-ProgressLine "Antigravity exited with code $exitCode"
    exit $exitCode
}
if ($null -eq $result -or $result.status -ne 'SUCCESS' -or [string]::IsNullOrWhiteSpace([string]$result['response'])) {
    Write-ProgressLine 'Antigravity returned no successful, nonempty result. Inspect events.jsonl and live.txt.'
    exit 1
}
Write-ProgressLine 'Worker pass completed; Grok acceptance review remains.'
exit 0
