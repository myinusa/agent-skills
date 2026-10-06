#requires -Version 7.0
<#
.SYNOPSIS
Runs one Gemini task through Antigravity in the current checkout or an isolated worktree.

.EXAMPLE
& "$HOME\.codex\skills\codex-to-gemini-delegation\scripts\Invoke-GeminiAgent.ps1" `
  -WorkingDirectory "C:\src\project-gemini-task" `
  -Model gemini-3.7-flash `
  -PromptFile "C:\temp\gemini-task.txt"

.EXAMPLE
& "$HOME\.codex\skills\codex-to-gemini-delegation\scripts\Invoke-GeminiAgent.ps1" `
  -WorkingDirectory "C:\src\project-gemini-task" `
  -Model gemini-3.7-flash `
  -PromptFile "C:\temp\gemini-task.txt" `
  -Mode Worktree `
  -AllowExistingChanges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$WorkingDirectory,

    [Parameter(Mandatory)]
    [ValidateSet('gemini-3.7-flash', 'gemini-3.7-flash-high', 'gemini-3.1-pro')]
    [string]$Model,

    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$PromptFile,

    [Parameter()]
    [ValidateSet('Direct', 'Worktree')]
    [string]$Mode = 'Direct',

    [Parameter()]
    [switch]$AllowExistingChanges
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

function Invoke-GitText {
    param(
        [Parameter(Mandatory)][string]$GitPath,
        [Parameter(Mandatory)][string]$WorkingPath,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$FailureMessage
    )

    $output = (& $GitPath -C $WorkingPath @Arguments 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage`n$output"
    }
    return $output
}

function Remove-AnsiEscapeSequences {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    return [regex]::Replace($Text, "`e\[[0-?]*[ -/]*[@-~]", '')
}

$workingPath = Resolve-ExistingPath -LiteralPath $WorkingDirectory -Label 'Working directory'
$promptPath = Resolve-ExistingPath -LiteralPath $PromptFile -Label 'Prompt file'

if ($AllowExistingChanges -and $Mode -ne 'Worktree') {
    throw 'AllowExistingChanges is available only in Worktree mode.'
}

if (-not (Test-Path -LiteralPath $workingPath -PathType Container)) {
    throw "Working directory is not a directory: $workingPath"
}
if (-not (Test-Path -LiteralPath $promptPath -PathType Leaf)) {
    throw "Prompt file is not a file: $promptPath"
}

$existingGitConfigCount = 0
if (-not [string]::IsNullOrWhiteSpace($env:GIT_CONFIG_COUNT)) {
    if (-not [int]::TryParse($env:GIT_CONFIG_COUNT, [ref]$existingGitConfigCount) -or $existingGitConfigCount -lt 0) {
        throw "GIT_CONFIG_COUNT must be a non-negative integer when set. Received: $($env:GIT_CONFIG_COUNT)"
    }
}

$gitSafeDirectory = [IO.Path]::GetFullPath($workingPath).TrimEnd('\', '/') -replace '\\', '/'
Set-Item -LiteralPath "Env:GIT_CONFIG_KEY_$existingGitConfigCount" -Value 'safe.directory'
Set-Item -LiteralPath "Env:GIT_CONFIG_VALUE_$existingGitConfigCount" -Value $gitSafeDirectory
$env:GIT_CONFIG_COUNT = [string]($existingGitConfigCount + 1)

$gitCommand = Get-Command git -ErrorAction Stop | Select-Object -First 1
$insideWorktree = Invoke-GitText -GitPath $gitCommand.Source -WorkingPath $workingPath `
    -Arguments @('rev-parse', '--is-inside-work-tree') `
    -FailureMessage "Working directory is not inside a Git worktree: $workingPath"
if ($insideWorktree -ne 'true') {
    throw "Working directory is not inside a Git worktree: $workingPath"
}

$topLevelRaw = Invoke-GitText -GitPath $gitCommand.Source -WorkingPath $workingPath `
    -Arguments @('rev-parse', '--show-toplevel') `
    -FailureMessage "Unable to determine the Git repository root for: $workingPath"
$topLevelPath = Resolve-ExistingPath -LiteralPath $topLevelRaw -Label 'Git repository root'

$normalizedWorkingPath = [IO.Path]::GetFullPath($workingPath).TrimEnd('\', '/')
$normalizedTopLevel = [IO.Path]::GetFullPath($topLevelPath).TrimEnd('\', '/')
if (-not $normalizedWorkingPath.Equals($normalizedTopLevel, [StringComparison]::OrdinalIgnoreCase)) {
    throw "WorkingDirectory must be the Git repository root. Resolved root: $normalizedTopLevel"
}

if ($Mode -eq 'Worktree') {
    $gitDirectoryRaw = Invoke-GitText -GitPath $gitCommand.Source -WorkingPath $workingPath `
        -Arguments @('rev-parse', '--path-format=absolute', '--git-dir') `
        -FailureMessage "Unable to determine the Git directory for: $workingPath"
    $commonDirectoryRaw = Invoke-GitText -GitPath $gitCommand.Source -WorkingPath $workingPath `
        -Arguments @('rev-parse', '--path-format=absolute', '--git-common-dir') `
        -FailureMessage "Unable to determine the common Git directory for: $workingPath"
    $gitDirectory = [IO.Path]::GetFullPath($gitDirectoryRaw).TrimEnd('\', '/')
    $commonDirectory = [IO.Path]::GetFullPath($commonDirectoryRaw).TrimEnd('\', '/')
    if ($gitDirectory.Equals($commonDirectory, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Worktree mode requires a linked Git worktree.'
    }

    & $gitCommand.Source -C $workingPath symbolic-ref -q HEAD *> $null
    if ($LASTEXITCODE -eq 0) {
        throw 'Worktree mode requires a detached HEAD.'
    }

    if (-not $AllowExistingChanges) {
        $worktreeStatus = Invoke-GitText -GitPath $gitCommand.Source -WorkingPath $workingPath `
            -Arguments @('status', '--porcelain=v1', '--untracked-files=all') `
            -FailureMessage "Unable to inspect worktree status: $workingPath"
        if (-not [string]::IsNullOrWhiteSpace($worktreeStatus)) {
            throw "Worktree mode requires a clean working directory:`n$worktreeStatus"
        }
    }
}

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

$agyCommand = Get-Command agy -ErrorAction Stop | Select-Object -First 1
$modelsOutput = (& $agyCommand.Source models 2>&1 | Out-String)
$modelsExitCode = $LASTEXITCODE
if ($modelsExitCode -ne 0) {
    throw "`agy models` failed with exit code $modelsExitCode.`n$modelsOutput"
}

$cleanModelsOutput = Remove-AnsiEscapeSequences -Text $modelsOutput
$modelSlug = switch ($Model) {
    'gemini-3.7-flash'      { 'gemini-3.7-flash-medium' }
    'gemini-3.7-flash-high' { 'gemini-3.7-flash-high' }
    'gemini-3.1-pro'        { 'gemini-3.1-pro-high' }
    default { throw "Unsupported model alias: $Model" }
}

$modelPattern = '(?<![A-Za-z0-9._-])' + [regex]::Escape($modelSlug) + '(?![A-Za-z0-9._-])'
$resolvedModels = @(
    [regex]::Matches(
        $cleanModelsOutput,
        $modelPattern,
        [Text.RegularExpressions.RegexOptions]::IgnoreCase
    ) |
        ForEach-Object { $_.Value.ToLowerInvariant() } |
        Sort-Object -Unique
)
if ($resolvedModels.Count -ne 1) {
    throw "Model alias '$Model' did not resolve uniquely to '$modelSlug'. Found $($resolvedModels.Count) match(es). Available model output:`n$cleanModelsOutput"
}

$agyArguments = @(
    '--dangerously-skip-permissions',
    '--disable-slash-commands',
    '--add-dir', $workingPath,
    '--print-timeout', '10m',
    '--model', $modelSlug,
    '-p', $prompt
)

$exitCode = 1
$agyOutput = @()
Push-Location -LiteralPath $workingPath
try {
    $agyOutput = @(& $agyCommand.Source @agyArguments 2>&1)
    $exitCode = if ($null -eq $LASTEXITCODE) { 1 } else { [int]$LASTEXITCODE }
}
finally {
    Pop-Location
}

$agyOutput | ForEach-Object { Write-Output $_ }

if ($exitCode -eq 0) {
    $cleanAgyOutput = Remove-AnsiEscapeSequences -Text ($agyOutput | Out-String)
    $headlessPermissionFailure =
        $cleanAgyOutput -match '(?im)^\s*jetski:\s*no output produced\b' -or
        $cleanAgyOutput -match '(?i)\ba tool required the ["'']command["''] permission\b'

    if ([string]::IsNullOrWhiteSpace($cleanAgyOutput) -or $headlessPermissionFailure) {
        [Console]::Error.WriteLine('Antigravity produced no usable agent result. Treating the exit-0 response as a failure.')
        exit 1
    }
}

exit $exitCode
