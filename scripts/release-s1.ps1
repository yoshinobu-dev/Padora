# Padora S1 release build: signed APK + self-contained Host ZIP + SHA256 checksums.

# Prerequisites: Flutter, .NET 8 SDK, run scripts/setup-android-signing.ps1 once.



$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")

$client = Join-Path $root "client"

$hostProj = Join-Path $root "host\Padora.Host\Padora.Host.csproj"

$dist = Join-Path $root "dist"

$hostOut = Join-Path $dist "host-win64"

$androidOut = Join-Path $dist "android"

$version = "1.0.0"



Write-Host "=== Padora S1 release build v$version ==="



# Android signing

$keystore = Join-Path $client "android\upload-keystore.jks"

if (-not (Test-Path $keystore)) {

    Write-Host "No release keystore. Running setup-android-signing.ps1 ..."

    & (Join-Path $PSScriptRoot "setup-android-signing.ps1")

}



Write-Host "`n[1/4] Flutter pub get + release APK ..."

Push-Location $client

flutter clean

flutter pub get

if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }

flutter build apk --release

if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }

Pop-Location



New-Item -ItemType Directory -Force -Path $androidOut | Out-Null

$apkSrc = Join-Path $client "build\app\outputs\flutter-apk\app-release.apk"

$apkDst = Join-Path $androidOut "Padora.apk"

Copy-Item -Force $apkSrc $apkDst

Write-Host "  -> $apkDst"



Write-Host "`n[2/4] Host publish (win-x64, self-contained, single-file) ..."

$nugetSources = dotnet nuget list source 2>$null

if ($nugetSources -match "ソースが見つかりませんでした|No sources found") {

    Write-Host "  Adding nuget.org source (required for self-contained runtime)..."

    dotnet nuget add source https://api.nuget.org/v3/index.json -n nuget.org | Out-Null

}

if (Test-Path $hostOut) {

    Remove-Item -Recurse -Force $hostOut

}

dotnet publish $hostProj `
    -c Release -r win-x64 `
    --self-contained true `
    -p:PublishSingleFile=true `
    -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:DebugType=None `
    -p:DebugSymbols=false `
    -o $hostOut

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "  -> $hostOut\Padora.Host.exe"



Write-Host "`n[3/4] ZIP Host ..."

$zipPath = Join-Path $dist "Padora-Host-win64.zip"

if (Test-Path $zipPath) { Remove-Item -Force $zipPath }

Compress-Archive -Path (Join-Path $hostOut "Padora.Host.exe") -DestinationPath $zipPath

Write-Host "  -> $zipPath"



Write-Host "`n[4/4] SHA256 checksums ..."

$checksumFile = Join-Path $dist "SHA256SUMS.txt"

$apkHash = (Get-FileHash $apkDst -Algorithm SHA256).Hash.ToLower()

$zipHash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()

@(

    "$apkHash  android/Padora.apk"

    "$zipHash  Padora-Host-win64.zip"

) | Set-Content -Path $checksumFile -Encoding UTF8

Write-Host "  -> $checksumFile"



Write-Host "`n=== Done ==="

Write-Host "Upload to GitHub Releases:"

Write-Host "  dist/android/Padora.apk"

Write-Host "  dist/Padora-Host-win64.zip"

Write-Host "  dist/SHA256SUMS.txt"

Write-Host ""

Write-Host "See docs/RELEASE.md for gh release create example."

