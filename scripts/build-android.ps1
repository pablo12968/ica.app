param([Parameter(Mandatory=$true)][string]$ApiUrl)
$ErrorActionPreference = 'Stop'
$serverUri = $null
if (-not [Uri]::TryCreate($ApiUrl, [UriKind]::Absolute, [ref]$serverUri) -or $serverUri.Scheme -ne 'https' -or $serverUri.Query -or $serverUri.Fragment -or $serverUri.UserInfo) {
    throw 'Indica la URL HTTPS publica de la API, sin claves, consultas ni fragmentos.'
}
$ApiUrl = $ApiUrl.TrimEnd('/')
$projectRoot = Split-Path $PSScriptRoot -Parent
if (Test-Path 'D:/IceCreamApp-tools/temp') {
    $env:TEMP = 'D:/IceCreamApp-tools/temp'
    $env:TMP = $env:TEMP
}
if (Test-Path 'D:/Android Studio/jbr/bin/java.exe') {
    $env:JAVA_HOME = 'D:/Android Studio/jbr'
}
$localSdk = Join-Path $projectRoot '.tools/android-sdk'
if (Test-Path $localSdk) { $env:ANDROID_HOME = $localSdk }
elseif (Test-Path 'D:/IceCreamApp-tools/android-sdk') {
    $env:ANDROID_HOME = 'D:/IceCreamApp-tools/android-sdk'
}
if (-not (Test-Path (Join-Path $projectRoot 'frontend/android/key.properties'))) {
    throw 'Falta frontend/android/key.properties. Conserva la firma original para poder actualizar la app instalada.'
}
$sourceRoot = Join-Path $projectRoot 'frontend'
$buildRoot = $sourceRoot
if (Test-Path 'D:/IceCreamApp-tools/release-build') {
    $buildRoot = 'D:/IceCreamApp-tools/release-build'
    $env:GRADLE_USER_HOME = 'D:/IceCreamApp-tools/gradle-cache'
    & robocopy $sourceRoot $buildRoot /E /XD build .dart_tool .gradle /XF '*.iml' 'hs_err_pid*.log' /MT:8 /R:1 /W:1 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { throw 'No se pudo preparar la copia de compilacion.' }
}
Push-Location $buildRoot
try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'No se pudieron resolver las dependencias.' }
    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas.' }
    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Falló el análisis.' }
    & flutter build apk --release "--dart-define=API_URL=$ApiUrl" --dart-define=DEMO_MODE=false
    if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación.' }
    $delivery = Join-Path $projectRoot 'entrega'
    New-Item -ItemType Directory -Force -Path $delivery | Out-Null
    $apk = Join-Path $delivery 'Ice-Cream-App.apk'
    Copy-Item -LiteralPath 'build/app/outputs/flutter-apk/app-release.apk' -Destination $apk -Force
    $checksum = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -LiteralPath (Join-Path $delivery 'SHA256.txt') -Value "$checksum  Ice-Cream-App.apk" -Encoding ascii
    Write-Output "APK para compartir: $apk"
} finally {
    Pop-Location
}
