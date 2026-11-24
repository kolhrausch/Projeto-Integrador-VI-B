# Gera a pasta android/ SEM sobrescrever o código-fonte do app (Windows / PowerShell).
# Uso (na raiz do repositório, com o Flutter instalado):  powershell -File scripts\bootstrap.ps1
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

if (Test-Path "android") {
    Write-Host "A pasta android/ ja existe - nada a fazer."
    exit 0
}

$backup = Join-Path $env:TEMP ("vitrine_bootstrap_" + [guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $backup | Out-Null
Copy-Item "lib", "test" -Destination $backup -Recurse
Copy-Item "pubspec.yaml", "analysis_options.yaml" -Destination $backup

flutter create --platforms=android --org br.edu.vitrine --project-name vitrine --no-pub .

Remove-Item "lib", "test" -Recurse -Force
Copy-Item (Join-Path $backup "lib"), (Join-Path $backup "test") -Destination "." -Recurse
Copy-Item (Join-Path $backup "pubspec.yaml"), (Join-Path $backup "analysis_options.yaml") -Destination "." -Force
Remove-Item $backup -Recurse -Force

$manifest = "android\app\src\main\AndroidManifest.xml"
$texto = Get-Content $manifest -Raw
$texto = $texto -replace 'android:label="vitrine"', 'android:label="Vitrine"'
Set-Content -Path $manifest -Value $texto -NoNewline

Write-Host "Projeto Android gerado em android/ (nome do app: Vitrine)."
