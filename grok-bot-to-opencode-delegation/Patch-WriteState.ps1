#requires -Version 7.0
$path = Join-Path $env:SKILL_PACKAGE_ROOT 'Invoke-OpenCodeAgent.ps1'
$text = [IO.File]::ReadAllText($path)
if ($text.Contains('Write-State with retries')) {
    Write-Output 'already-patched'
    exit 0
}
$old = @'
function Write-State {
    $state.updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $temporary = "$watchPath.new"
    [IO.File]::WriteAllText($temporary, ($state | ConvertTo-Json -Depth 8))
    [IO.File]::Move($temporary, $watchPath, $true)
}
'@
$new = @'
function Write-State {
    # Write-State with retries: Windows temp files can be briefly locked by AV/indexers.
    $state.updatedAt = [DateTimeOffset]::UtcNow.ToString('o')
    $temporary = "$watchPath.new"
    $payload = $state | ConvertTo-Json -Depth 8
    $attempts = 0
    while ($true) {
        try {
            [IO.File]::WriteAllText($temporary, $payload)
            if (Test-Path -LiteralPath $watchPath) {
                [IO.File]::Copy($temporary, $watchPath, $true)
                Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
            } else {
                [IO.File]::Move($temporary, $watchPath)
            }
            break
        } catch {
            $attempts++
            if ($attempts -ge 10) {
                Write-Live "Write-State warning after $attempts attempts: $($_.Exception.Message)"
                break
            }
            Start-Sleep -Milliseconds (40 * $attempts)
        }
    }
}
'@
if (-not $text.Contains($old)) { throw 'Write-State block not found exactly; refusing to patch' }
$updated = $text.Replace($old, $new)
[IO.File]::WriteAllText($path, $updated)
Write-Output 'patched-ok'
