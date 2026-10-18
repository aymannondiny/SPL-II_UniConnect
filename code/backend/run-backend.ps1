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

Write-Host 'Loaded backend environment from the repository .env file.'
Write-Host 'Starting UniConnect with the dev profile (Java 21 required).'
Set-Location -LiteralPath $backendDirectory
& (Join-Path $backendDirectory 'mvnw.cmd') 'spring-boot:run' '-Dspring-boot.run.profiles=dev'
exit $LASTEXITCODE
