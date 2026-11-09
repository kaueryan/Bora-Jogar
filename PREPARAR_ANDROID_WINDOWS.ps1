# Executar no PowerShell com Node.js 22+, Android Studio e Android SDK instalados.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
npm install
if (-not (Test-Path './android')) { npx cap add android }
npx cap sync android
npx cap open android
Write-Host 'Android Studio aberto. Use Build > Build Bundle(s) / APK(s) > Build APK(s).'
