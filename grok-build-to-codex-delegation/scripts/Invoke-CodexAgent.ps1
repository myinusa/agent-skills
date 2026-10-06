#requires -Version 7.0
<#
.SYNOPSIS
Runs repository work with Codex GPT-5.6 Luna or Sol at high reasoning.

.EXAMPLE
& '.grok\skills\codex-delegation\scripts\Invoke-CodexAgent.ps1' `
  -WorkingDirectory (Get-Location) `
  -PromptFile (Join-Path $env:TEMP 'codex-task.txt') `
  -Model Sol `
  -UseSubagents
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
$codexArguments = @(
    'exec'
    '--ephemeral'
    '--dangerously-bypass-approvals-and-sandbox'
    $multiAgentFeatureFlag, 'multi_agent'
    '--model', $modelId
    '--config', 'model_reasoning_effort="high"'
    '-c', 'service_tier="fast"'
    '--cd', $normalizedRepositoryRoot
    '-'
)

$prompt | & $codexCommand.Source @codexArguments 2>&1 | ForEach-Object { Write-Output $_ }
$exitCode = if ($null -eq $LASTEXITCODE) { 1 } else { [int]$LASTEXITCODE }

exit $exitCode
