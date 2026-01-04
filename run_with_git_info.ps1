param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$gitBranch = (git rev-parse --abbrev-ref HEAD).Trim()
$gitSha = (git rev-parse --short HEAD).Trim()

$flutterArgs = if ($Args.Count -eq 0) { @('run') } else { $Args }
flutter @flutterArgs --dart-define=GIT_BRANCH=$gitBranch --dart-define=GIT_SHA=$gitSha
