# Creates upload-keystore.jks + key.properties for release APK signing.
# Run once per machine. BACK UP both files — losing the keystore blocks Play updates.

$ErrorActionPreference = "Stop"
$androidDir = Join-Path $PSScriptRoot "..\client\android"
$keystore = Join-Path $androidDir "upload-keystore.jks"
$props = Join-Path $androidDir "key.properties"

if (Test-Path $keystore) {
    Write-Host "Keystore already exists: $keystore"
    exit 0
}

if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Error "keytool not found. Install JDK 17+ and add to PATH."
}

# Dev-only default password. Change storePassword/keyPassword before public release if desired.
$storePass = "wolfpad-upload-store"
$keyPass = "wolfpad-upload-key"

Write-Host "Generating upload keystore..."
keytool -genkeypair -v `
    -keystore $keystore `
    -storetype JKS `
    -keyalg RSA -keysize 2048 -validity 10000 `
    -alias upload `
    -storepass $storePass -keypass $keyPass `
    -dname "CN=WolfPad, OU=Mobile, O=WolfPad, L=Local, ST=Local, C=JP"

@(
    "storePassword=$storePass"
    "keyPassword=$keyPass"
    "keyAlias=upload"
    "storeFile=upload-keystore.jks"
) | Set-Content -Path $props -Encoding utf8NoBOM

Write-Host ""
Write-Host "Created:"
Write-Host "  $keystore"
Write-Host "  $props"
Write-Host ""
Write-Host "IMPORTANT: Back up upload-keystore.jks and key.properties offline."
Write-Host "           Never commit them to git (already gitignored)."
