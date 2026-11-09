$ErrorActionPreference = 'Stop'
if (Test-Path 'D:/IceCreamApp-tools/temp') {
    $env:TEMP = 'D:/IceCreamApp-tools/temp'
    $env:TMP = $env:TEMP
}
Push-Location (Join-Path (Split-Path $PSScriptRoot -Parent) 'frontend')
try {
    Write-Output 'Abre http://127.0.0.1:8080 en tu navegador.'
    Write-Output 'Tras cambiar el código, pulsa R aquí y recarga la página si es necesario.'
    & flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8080 --dart-define=DEMO_MODE=true
} finally {
    Pop-Location
}
