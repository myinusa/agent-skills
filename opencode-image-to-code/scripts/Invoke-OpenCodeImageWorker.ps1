#requires -Version 7.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$WorkingDirectory,
    [Parameter(Mandatory)][string]$PromptFile,
    [ValidateNotNullOrEmpty()][string]$Model = 'opencode-go/muse-spark-1.3-contributor',
    [string[]]$Images = @(),
    [string]$SessionId,
    [string]$Variant,
    [string]$RunDirectory,
    [switch]$Background
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workingPath = (Resolve-Path -LiteralPath $WorkingDirectory).Path
if (-not (Test-Path -LiteralPath $workingPath -PathType Container)) { throw 'WorkingDirectory must be a directory.' }
$promptPath = (Resolve-Path -LiteralPath $PromptFile).Path
$prompt = [IO.File]::ReadAllText($promptPath, [Text.UTF8Encoding]::new($false, $true))
if ([string]::IsNullOrWhiteSpace($prompt)) { throw 'PromptFile must contain a UTF-8 task contract.' }
if ($Model -and $Model -notmatch '^[^/\s]+/\S+$') { throw 'Model must use provider/model format.' }
$launcher = Join-Path $env:USERPROFILE 'bin\opencode-no-plugins.ps1'
if (-not (Test-Path -LiteralPath $launcher -PathType Leaf)) { throw "Missing launcher: $launcher" }
$pwsh = (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source

if (-not $RunDirectory) { $RunDirectory = Join-Path ([IO.Path]::GetTempPath()) ('opencode-image-to-code-' + [guid]::NewGuid().ToString('N')) }
$RunDirectory = [IO.Path]::GetFullPath($RunDirectory)
New-Item -ItemType Directory -Path $RunDirectory -Force | Out-Null
$watchPath = Join-Path $RunDirectory 'watch.json'
$eventsPath = Join-Path $RunDirectory 'events.jsonl'
$livePath = Join-Path $RunDirectory 'live.txt'
$lastMessagePath = Join-Path $RunDirectory 'last-message.txt'
$stderrPath = Join-Path $RunDirectory 'stderr.txt'
if (Test-Path -LiteralPath $watchPath) { throw "RunDirectory already contains a run: $RunDirectory" }

if ($Background) {
    $parameters = [ordered]@{ WorkingDirectory = $workingPath; PromptFile = $promptPath; RunDirectory = $RunDirectory }
    foreach ($key in @('Model', 'SessionId', 'Variant')) {
        $value = Get-Variable -Name $key -ValueOnly
        if ($value) { $parameters[$key] = $value }
    }
    $invocation = "& '" + $PSCommandPath.Replace("'", "''") + "'"
    foreach ($key in $parameters.Keys) { $invocation += " -$key '" + $parameters[$key].Replace("'", "''") + "'" }
    if ($Images.Count) {
        $invocation += ' -Images @(' + (($Images | ForEach-Object { "'" + $_.Replace("'", "''") + "'" }) -join ',') + ')'
    }
    $invocation += " 1>'" + (Join-Path $RunDirectory 'bridge.stdout.txt').Replace("'", "''") + "' 2>'" + (Join-Path $RunDirectory 'bridge.stderr.txt').Replace("'", "''") + "' 3>&1 4>&1 5>&1 6>&1"
    $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($invocation))
    # Give the worker its own hidden console and let it own its output files.
    # Parent-owned redirected pipes keep command transports open until worker exit.
    $child = Start-Process -FilePath $pwsh -ArgumentList @('-NoProfile', '-EncodedCommand', $encoded) -WindowStyle Hidden -PassThru
    [ordered]@{ status = 'launched'; bridgePid = $child.Id; runDirectory = $RunDirectory; watchPath = $watchPath; lastMessagePath = $lastMessagePath } | ConvertTo-Json -Compress
    $child.Dispose()
    exit 0
}

$state = [ordered]@{
    status = 'starting'; repo = $workingPath; runDirectory = $RunDirectory
    contractPath = $promptPath; model = $Model; agent = 'build'; sessionId = $SessionId
    bridgePid = $PID; workerPid = $null; startedAt = [DateTimeOffset]::UtcNow.ToString('o')
    updatedAt = $null; finishedAt = $null; exitCode = $null; error = $null
    watchPath = $watchPath; eventsPath = $eventsPath; livePath = $livePath
    lastMessagePath = $lastMessagePath; stderrPath = $stderrPath
}
function Write-State {
    $state.updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $temporary = "$watchPath.new"
    [IO.File]::WriteAllText($temporary, ($state | ConvertTo-Json -Depth 8))
    # Windows readers can briefly prevent replacement of the status file.
    for ($attempt = 0; ; $attempt++) {
        try {
            [IO.File]::Move($temporary, $watchPath, $true)
            break
        }
        catch [IO.IOException], [UnauthorizedAccessException] {
            $nativeError = $_.Exception.GetBaseException().HResult -band 0xffff
            if ($attempt -ge 10 -or $nativeError -notin @(5, 32, 33)) { throw }
            Start-Sleep -Milliseconds 100
        }
    }
}
function Write-Live([string]$Text) {
    $entry = "$(Get-Date -Format HH:mm:ss)  $Text"
    [IO.File]::AppendAllText($livePath, $entry + [Environment]::NewLine)
    Write-Output $entry
}
foreach ($path in @($eventsPath, $livePath, $lastMessagePath, $stderrPath)) { [IO.File]::WriteAllText($path, '') }
Write-State
$process = $null
$stderrTask = $null
$exitCode = 1
$stopped = $false
$eventError = $false
try {
    $info = [Diagnostics.ProcessStartInfo]::new($pwsh)
    $info.WorkingDirectory = $workingPath
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.WindowStyle = 'Hidden'
    $info.RedirectStandardInput = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.StandardInputEncoding = [Text.UTF8Encoding]::new($false)
    $info.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
    $info.StandardErrorEncoding = [Text.UTF8Encoding]::new($false)
    foreach ($arg in @('-NoProfile', '-File', $launcher, 'run', '--agent', 'build', '--format', 'json')) { $info.ArgumentList.Add($arg) }
    if ($Model) { $info.ArgumentList.Add('--model'); $info.ArgumentList.Add($Model) }
    if ($SessionId) { $info.ArgumentList.Add('--session'); $info.ArgumentList.Add($SessionId) }
    if ($Variant) { $info.ArgumentList.Add('--variant'); $info.ArgumentList.Add($Variant) }
    foreach ($imagePath in $Images) {
        $resolvedImage = (Resolve-Path -LiteralPath $imagePath).Path
        if (-not (Test-Path -LiteralPath $resolvedImage -PathType Leaf)) { throw "Image is not a file: $imagePath" }
        $info.ArgumentList.Add('--file'); $info.ArgumentList.Add($resolvedImage)
    }
    # The launcher resolves and regenerates only these known profile/cache paths.
    $info.Environment['OPENCODE_NO_PLUGINS_XDG_CONFIG_HOME'] = Join-Path $env:USERPROFILE '.config\opencode-no-plugins'
    $info.Environment['OPENCODE_NO_PLUGINS_CACHE_HOME'] = Join-Path $env:USERPROFILE '.cache\opencode-no-plugins'
    $info.Environment['OPENCODE_SOURCE_CONFIG_HOME'] = Join-Path $env:USERPROFILE '.config\opencode'
    $info.Environment['OPENCODE_CONFIG_CONTENT'] = '{"default_agent":"build","permission":"allow","agent":{"build":{"permission":"allow"}},"share":"disabled"}'
    $info.Environment['OPENCODE_PERMISSION'] = '{"*":"allow"}'
    $info.Environment['OPENCODE_PURE'] = 'true'
    $info.Environment['OPENCODE_AUTO_SHARE'] = 'false'
    $process = [Diagnostics.Process]::Start($info)
    $state.workerPid = $process.Id
    $state.status = 'running'
    Write-State
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $process.StandardInput.Write($prompt)
    $process.StandardInput.Close()
    Write-Live "OpenCode running in $workingPath; artifacts: $RunDirectory"
    while ($null -ne ($line = $process.StandardOutput.ReadLine())) {
        [IO.File]::AppendAllText($eventsPath, $line + "`n")
        try { $event = ConvertFrom-Json -InputObject $line -AsHashtable -ErrorAction Stop }
        catch { Write-Live $line; continue }
        if ($event.sessionID) { $state.sessionId = $event.sessionID }
        switch ($event.type) {
            'text' {
                [IO.File]::AppendAllText($lastMessagePath, $event.part.text + "`n")
                Write-Live $event.part.text
            }
            'tool_use' { Write-Live "tool $($event.part.tool): $($event.part.state.status)" }
            'step_finish' { $stopped = $event.part.reason -eq 'stop'; Write-Live "step finished: $($event.part.reason)" }
            'error' { $eventError = $true; $state.error = $event.error | ConvertTo-Json -Depth 12 -Compress; Write-Live "OpenCode error: $($state.error)" }
            default { Write-Live $event.type }
        }
        Write-State
    }
    $process.WaitForExit()
    $exitCode = $process.ExitCode
    if ($exitCode -ne 0 -and -not $state.error) { $state.error = "OpenCode exited with code $exitCode. Inspect events and stderr." }
    if ($exitCode -eq 0 -and ($eventError -or -not $stopped)) {
        $exitCode = 1
        if (-not $state.error) { $state.error = 'OpenCode exited without a completed stop event. Inspect events and stderr.' }
    }
}
catch {
    $state.error = $_.Exception.Message
    $exitCode = 1
    Write-Live "Bridge error: $($state.error)"
}
finally {
    if ($process) {
        if (-not $process.HasExited) { $process.Kill($true); $process.WaitForExit() }
        if ($stderrTask) {
            $stderrText = $stderrTask.GetAwaiter().GetResult()
            [IO.File]::WriteAllText($stderrPath, $stderrText)
            if ($stderrText.Trim()) { Write-Live $stderrText.Trim() }
        }
        $process.Dispose()
    }
    $state.exitCode = $exitCode
    $state.status = if ($exitCode -eq 0) { 'completed' } else { 'failed' }
    $state.finishedAt = [DateTimeOffset]::UtcNow.ToString('o')
    Write-State
    Write-Live "OpenCode $($state.status), exit $exitCode; watch: $watchPath"
}
exit $exitCode
