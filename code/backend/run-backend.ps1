$ErrorActionPreference = 'Stop'

$backendDirectory = $PSScriptRoot
$repositoryDirectory = (Resolve-Path (Join-Path $backendDirectory '..\..')).Path
$environmentFile = Join-Path $repositoryDirectory '.env'

if (-not (Test-Path -LiteralPath $environmentFile)) {
  throw "Missing $environmentFile. Copy .env.example to .env and configure the database values first."
}

Get-Content -LiteralPath $environmentFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#') -or -not $line.Contains('=')) {
    return
  }

  $parts = $line.Split('=', 2)
  $name = $parts[0].Trim()
  $value = $parts[1].Trim()
  if (($value.StartsWith("'") -and $value.EndsWith("'")) -or
      ($value.StartsWith('"') -and $value.EndsWith('"'))) {
    $value = $value.Substring(1, $value.Length - 2)
  }
  [Environment]::SetEnvironmentVariable($name, $value, 'Process')
}

$requiredVariables = @('DB_URL', 'DB_USERNAME', 'DB_PASSWORD')
$missingVariables = @(
  $requiredVariables | Where-Object {
    [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_, 'Process'))
  }
)
if ($missingVariables.Count -gt 0) {
  throw "Set these required values in the repository .env file: $($missingVariables -join ', ')"
}

$backendPort = 8080
if (-not [string]::IsNullOrWhiteSpace($env:SERVER_PORT)) {
  if (-not [int]::TryParse($env:SERVER_PORT, [ref]$backendPort) -or
      $backendPort -lt 1 -or $backendPort -gt 65535) {
    throw 'SERVER_PORT must be a number between 1 and 65535.'
  }
}

$activeListeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
if ($activeListeners | Where-Object { $_.Port -eq $backendPort }) {
  Write-Warning "Port $backendPort is already in use. No second backend was started."
  Write-Host 'Keep using the existing server, or stop it before running this command again.'
  return
}

Write-Host 'Loaded backend environment from the repository .env file.'
Write-Host 'Starting UniConnect with the dev profile (Java 21 required).'
Push-Location -LiteralPath $backendDirectory
try {
  & (Join-Path $backendDirectory 'mvnw.cmd') 'spring-boot:run' '-Dspring-boot.run.profiles=dev'
  $backendExitCode = $LASTEXITCODE
} finally {
  Pop-Location
}
exit $backendExitCode
