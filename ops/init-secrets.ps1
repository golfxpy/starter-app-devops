[CmdletBinding()]
param(
    [switch]$Force,
    [string]$SecretDirectory
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($SecretDirectory)) {
    $SecretDirectory = Join-Path $repositoryRoot 'secrets'
}
$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$null = New-Item -ItemType Directory -Path $SecretDirectory -Force

function New-RandomSecretFile {
    param([Parameter(Mandatory)][string]$Path)

    if ((Test-Path -LiteralPath $Path) -and -not $Force) {
        Write-Host "Keeping existing secret: $Path"
        return
    }

    $bytes = New-Object byte[] 48
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $generator.GetBytes($bytes)
    }
    finally {
        $generator.Dispose()
    }

    [System.IO.File]::WriteAllText($Path, [Convert]::ToBase64String($bytes), $utf8WithoutBom)
    Write-Host "Generated secret: $Path"
}

New-RandomSecretFile -Path (Join-Path $SecretDirectory 'postgres_password.txt')
New-RandomSecretFile -Path (Join-Path $SecretDirectory 'backup_encryption_passphrase.txt')
