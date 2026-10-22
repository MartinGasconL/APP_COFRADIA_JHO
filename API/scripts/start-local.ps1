param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '..\.env')
)

$envPath = [System.IO.Path]::GetFullPath($EnvFile)
if (Test-Path -LiteralPath $envPath) {
    Get-Content -LiteralPath $envPath | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith('#')) {
            return
        }

        if ($line -notmatch '^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
            throw "Linea invalida en ${envPath}: $line"
        }

        $name = $matches[1]
        $value = $matches[2].Trim()
        if ($value.Length -ge 2 -and (
            ($value.StartsWith('"') -and $value.EndsWith('"')) -or
            ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        Set-Item -Path "Env:$($name)" -Value $value
    }
    Write-Host "Variables cargadas desde $envPath"
} else {
    Write-Host "No existe $envPath; se usaran los valores por defecto de application.yaml"
}

& mvn.cmd spring-boot:run '-Dspring-boot.run.profiles=local'
exit $LASTEXITCODE