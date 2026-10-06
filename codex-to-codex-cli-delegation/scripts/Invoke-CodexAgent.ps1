#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$PromptFile,
    [Parameter(Mandatory)][string]$StateDirectory,
    [switch]$Resume,
    [string]$Model = 'Luna',
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max', 'ultra')][string]$ReasoningEffort = 'high',
    [ValidateSet('fast', 'standard')][string]$ServiceTier = 'fast',
    [ValidateSet('ReadOnly', 'WorkspaceWrite', 'FullAccess')][string]$PermissionMode = 'FullAccess',
    [switch]$UseSubagents
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$workingPath = (Resolve-Path -LiteralPath $WorkingDirectory).Path
if (-not (Test-Path -LiteralPath $workingPath -PathType Container)) { throw 'WorkingDirectory must be a directory.' }
$promptPath = (Resolve-Path -LiteralPath $PromptFile).Path
$prompt = [IO.File]::ReadAllText($promptPath, [Text.UTF8Encoding]::new($false, $true))
if ([string]::IsNullOrWhiteSpace($prompt)) { throw 'PromptFile must contain a task.' }
$codex = (Get-Command codex -CommandType Application, ExternalScript -ErrorAction Stop | Select-Object -First 1).Source
$rootOutput = & git -C $workingPath rev-parse --show-toplevel 2>&1
if ($LASTEXITCODE -ne 0) { throw "WorkingDirectory must be inside a Git repository: $rootOutput" }
$repositoryRoot = [IO.Path]::GetFullPath(($rootOutput | Out-String).Trim())
$statePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($StateDirectory)
$comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
$rootPrefix = $repositoryRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
if ($statePath.Equals($repositoryRoot, $comparison) -or $statePath.StartsWith($rootPrefix, $comparison)) {
    throw 'StateDirectory must be outside the repository.'
}
[IO.Directory]::CreateDirectory($statePath) | Out-Null
$sessionPath = Join-Path $statePath 'session.json'
$lockPath = Join-Path $statePath 'worker.lock'
$lock = [IO.File]::Open($lockPath, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::Read)
$exitCode = 1
$state = $null
try {
    $lockBytes = [Text.Encoding]::UTF8.GetBytes("pid=$PID")
    $lock.Write($lockBytes, 0, $lockBytes.Length)
    $lock.Flush()
    $session = $null
    if ($Resume) {
        $session = Get-Content -LiteralPath $sessionPath -Raw | ConvertFrom-Json
        if (-not $workingPath.Equals($session.working_directory, $comparison)) { throw 'Resume requires the saved working directory.' }
        if ([string]::IsNullOrWhiteSpace($session.session_id)) { throw 'The saved state has no resumable session ID.' }
        foreach ($setting in @('Model', 'ReasoningEffort', 'ServiceTier', 'PermissionMode', 'UseSubagents')) {
            if ($PSBoundParameters.ContainsKey($setting)) { throw "Resume retains saved settings; omit -$setting." }
        }
        $Model = $session.model
        $ReasoningEffort = $session.reasoning_effort
        $ServiceTier = $session.service_tier
        $PermissionMode = $session.permission_mode
        $UseSubagents = [bool]$session.use_subagents
    }
    elseif (Test-Path -LiteralPath $sessionPath) { throw 'This worker already has a session. Use -Resume or a fresh StateDirectory.' }
    $modelId = switch ($Model) { 'Luna' { 'gpt-5.6-luna' } 'Sol' { 'gpt-5.6-sol' } default { $Model } }
    if ([string]::IsNullOrWhiteSpace($modelId)) { throw 'Model must be specified.' }
    $runPath = Join-Path $statePath ([guid]::NewGuid().ToString())
    [IO.Directory]::CreateDirectory($runPath) | Out-Null
    $eventsPath = Join-Path $runPath 'events.jsonl'
    $reportPath = Join-Path $runPath 'report.txt'
    $contractPath = Join-Path $runPath 'prompt.txt'
    $prompt = @"
/goal
Establish or continue a native Codex goal for the complete assignment below. Use get_goal to inspect an existing goal on resume; create_goal starts the assigned objective when needed. Keep an unfinished goal active across progress reports and phase boundaries. Mark it complete only when the entire allocated scope and its acceptance criteria are satisfied. A new assignment after a completed goal starts a new goal. Report missing native goal capability as an execution issue. Set a token budget only when the user explicitly supplied one.

Assigned working directory: $workingPath
Before editing, verify the working directory and resolve every edit target against this exact directory. Use absolute paths for apply_patch and other file edits. Never edit another checkout or worktree. If a tool targets a different directory, stop that edit and report the mismatch; continue only after correcting the target. These requirements apply to this invocation and resumed work.
Keep implementation within the assigned task. Return a compact report with summary, changed_files, validation, risks and unresolved, including the absolute paths of changed files.
Complete implementation across the full assignment before builds, test suites and broad validation. Phase boundaries and progress reports alone are insufficient reasons to run checks. Earlier targeted checks require a concrete failure or dependency preventing further implementation; state that reason. Run generation needed for subsequent implementation when required. Coordinate heavy validation with the supervisor: report readiness and pending commands, keeping the goal unfinished, unless this invocation already assigns the validation slot. Reuse sufficient existing validation evidence; rerun affected checks after relevant corrections. Apply explicit task-specific validation requirements from the contract.

$prompt
"@
    if ($UseSubagents) { $prompt = "Subagents are requested for suitable independent work. Integrate their work before reporting completion.`n`n$prompt" }
    [IO.File]::WriteAllText($contractPath, $prompt, [Text.UTF8Encoding]::new($false))
    $state = [ordered]@{
        session_id = if ($Resume) { $session.session_id } else { $null }
        working_directory = $workingPath
        model = $modelId
        reasoning_effort = $ReasoningEffort
        service_tier = $ServiceTier
        permission_mode = $PermissionMode
        use_subagents = [bool]$UseSubagents
        run_directory = $runPath
        status = 'running'
        exit_code = $null
        usage = $null
    }
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
    $sandbox = switch ($PermissionMode) { 'ReadOnly' { 'read-only' } 'WorkspaceWrite' { 'workspace-write' } 'FullAccess' { 'danger-full-access' } }
    $arguments = @('exec', '-C', $workingPath)
    if ($Resume) { $arguments += 'resume' }
    $arguments += @('--model', $modelId, '-c', "model_reasoning_effort=`"$ReasoningEffort`"", '-c', "service_tier=`"$ServiceTier`"")
    if ($PermissionMode -eq 'FullAccess') {
        $arguments += '--dangerously-bypass-approvals-and-sandbox'
    }
    else {
        $arguments += @('-c', "sandbox_mode=`"$sandbox`"", '-c', 'approval_policy="never"')
    }
    $arguments += @('--enable', 'goals', $(if ($UseSubagents) { '--enable' } else { '--disable' }), 'multi_agent', '--json', '-o', $reportPath)
    if ($Resume) { $arguments += $session.session_id }
    $arguments += '-'
    $log = [IO.StreamWriter]::new($eventsPath, $false, [Text.UTF8Encoding]::new($false))
    $log.AutoFlush = $true
    $turnFailed = $false
    $turnCompleted = $false
    Push-Location -LiteralPath $workingPath
    try {
        $prompt | & $codex @arguments 2>&1 | ForEach-Object {
            $line = $_.ToString()
            $log.WriteLine($line)
            $event = $null
            try { $event = $line | ConvertFrom-Json -AsHashtable -ErrorAction Stop } catch { }
            if ($event -is [System.Collections.IDictionary]) {
                $eventType = $event['type']
                if ($eventType -eq 'thread.started') {
                    if ($Resume -and $event['thread_id'] -ne $session.session_id) { throw 'Codex returned a different session ID on resume.' }
                    $state.session_id = $event['thread_id']
                    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
                }
                if ($eventType -eq 'turn.completed') { $turnCompleted = $true; $state.usage = $event['usage'] }
                if ($eventType -eq 'turn.failed') { $turnFailed = $true }
            }
        }
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0 -and ($turnFailed -or -not $turnCompleted -or -not $state.session_id -or -not (Test-Path -LiteralPath $reportPath))) { $exitCode = 1 }
    }
    finally { Pop-Location; $log.Dispose() }
    $state.status = if ($exitCode -eq 0) { 'completed' } else { 'failed' }
    $state.exit_code = $exitCode
    $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
    [ordered]@{
        status = $state.status
        exit_code = $exitCode
        session_id = $state.session_id
        state_file = $sessionPath
        event_log = $eventsPath
        report_file = $reportPath
        usage = $state.usage
        report = if (Test-Path -LiteralPath $reportPath) { Get-Content -LiteralPath $reportPath -Raw } else { $null }
    } | ConvertTo-Json -Depth 6
}
catch {
    if ($null -ne $state) {
        $state.status = 'failed'
        $state.exit_code = 1
        $state | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $sessionPath -Encoding utf8
    }
    throw
}
finally {
    $lock.Dispose()
    Remove-Item -LiteralPath $lockPath
}
exit $exitCode
