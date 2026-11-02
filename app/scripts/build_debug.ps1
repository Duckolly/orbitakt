$ErrorActionPreference = 'Stop'
$env:CI = 'true'
$env:BOT = 'true'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:DART_SUPPRESS_ANALYTICS = 'true'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) { throw 'Install Flutter 3.35.7 and add flutter/bin to PATH. See START_HERE.md.' }
$info = (flutter --version --machine | Out-String | ConvertFrom-Json)
if ($LASTEXITCODE -ne 0) { throw 'Cannot read Flutter version.' }
if ($info.frameworkVersion -ne '3.35.7') { throw "Expected Flutter 3.35.7, found $($info.frameworkVersion). Use the pinned SDK." }
flutter pub get --enforce-lockfile
if ($LASTEXITCODE -ne 0) { throw 'Dependency restore failed.' }
flutter analyze --no-pub
if ($LASTEXITCODE -ne 0) { throw 'Static analysis failed.' }
flutter test --no-pub --concurrency=1
if ($LASTEXITCODE -ne 0) { throw 'Tests failed.' }
flutter build apk --debug --no-pub
if ($LASTEXITCODE -ne 0) { throw 'APK build failed.' }
Push-Location 'android'
try {
    & .\gradlew.bat :app:testDebugUnitTest :app:lintDebug --no-daemon --max-workers=1
    if ($LASTEXITCODE -ne 0) { throw 'Native tests or Android Lint failed. Check JAVA_HOME (JDK 17).' }
} finally { Pop-Location }

$apk = Join-Path (Get-Location) 'build/app/outputs/flutter-apk/app-debug.apk'
if (-not (Test-Path $apk)) { throw 'APK not found after build.' }
Get-FileHash $apk -Algorithm SHA256
Write-Host "APK: $apk"
Write-Host 'Device behavior and battery require a separate phone check.'
