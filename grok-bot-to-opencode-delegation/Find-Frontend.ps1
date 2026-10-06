#requires -Version 7.0
$ports = 4500,5173,3000,4173,8080,5174,4321,24678,8000,4200,5175
Write-Output '=== LISTENERS ==='
foreach ($line in (netstat -ano | Select-String 'LISTENING')) {
  $text = [string]$line
  foreach ($p in $ports) {
    if ($text -match (":$p\s")) { Write-Output $text }
  }
}
Write-Output '=== NODE CMDS ==='
foreach ($proc in (Get-CimInstance Win32_Process -Filter "Name = 'node.exe'")) {
  $cmd = [string]$proc.CommandLine
  if ($cmd -match 'vite|foundry|concept-zulu|4500|web') {
    Write-Output ("{0}`t{1}" -f $proc.ProcessId, $cmd)
  }
}
