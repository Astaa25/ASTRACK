# ============================================================
# ASTRACK Automated Release Build Script (PowerShell)
# Builds universal APK, obfuscates symbols, generates SHA-256
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "🚀 [1/5] Extracting version from pubspec.yaml..." -ForegroundColor Cyan
$pubspecContent = Get-Content "pubspec.yaml"
$versionLine = $pubspecContent | Where-Object { $_ -match '^version:\s*(.+)$' }
if (-not $versionLine) {
    Write-Error "Could not parse version from pubspec.yaml"
    exit 1
}
$version = ($versionLine -replace '^version:\s*', '').Trim()
Write-Host "Target Version: $version" -ForegroundColor Green

Write-Host "🧹 [2/5] Creating symbols directory..." -ForegroundColor Cyan
if (-not (Test-Path "build\symbols")) {
    New-Item -ItemType Directory -Path "build\symbols" -Force | Out-Null
}

Write-Host "🔨 [3/5] Building release APK with obfuscation..." -ForegroundColor Cyan
flutter build apk --release --obfuscate --split-debug-info=build/symbols

$sourceApk = "build\app\outputs\flutter-apk\app-release.apk"
$targetApk = "build\app\outputs\flutter-apk\ASTRACK-v$version.apk"

if (-not (Test-Path $sourceApk)) {
    Write-Error "Release APK not found at $sourceApk"
    exit 1
}

Write-Host "📦 [4/5] Copying APK to $targetApk..." -ForegroundColor Cyan
Copy-Item -Path $sourceApk -Destination $targetApk -Force

Write-Host "🔐 [5/5] Calculating SHA-256 Checksum..." -ForegroundColor Cyan
$hashResult = Get-FileHash -Path $targetApk -Algorithm SHA256
$sha256 = $hashResult.Hash.ToLower()

$symbolsZip = "build\symbols\symbols-v$version.zip"
Write-Host "🗜️ Archiving debug symbols to $symbolsZip..." -ForegroundColor Cyan
Compress-Archive -Path "build\symbols\*" -DestinationPath $symbolsZip -Force

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "🎉 ASTRACK Release Build Successful!" -ForegroundColor Green
Write-Host "Version:     $version" -ForegroundColor White
Write-Host "Output APK:  $targetApk" -ForegroundColor White
Write-Host "SHA-256:     $sha256" -ForegroundColor Yellow
Write-Host "Symbols Zip: $symbolsZip" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Green
