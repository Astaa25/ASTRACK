#!/usr/bin/env bash
# ============================================================
# ASTRACK Automated Release Build Script (Bash)
# Builds universal APK, obfuscates symbols, generates SHA-256
# ============================================================

set -e

echo "🚀 [1/5] Extracting version from pubspec.yaml..."
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
echo "Target Version: $VERSION"

echo "🧹 [2/5] Cleaning and creating symbols directory..."
mkdir -p build/symbols

echo "🔨 [3/5] Building release APK with obfuscation..."
flutter build apk --release --obfuscate --split-debug-info=build/symbols

SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
TARGET_APK="build/app/outputs/flutter-apk/ASTRACK-v${VERSION}.apk"

if [ ! -f "$SOURCE_APK" ]; then
    echo "❌ Error: Release APK not found at $SOURCE_APK"
    exit 1
fi

echo "📦 [4/5] Renaming APK to $TARGET_APK..."
cp "$SOURCE_APK" "$TARGET_APK"

echo "🔐 [5/5] Calculating SHA-256 Checksum..."
if command -v sha256sum &> /dev/null; then
    SHA256=$(sha256sum "$TARGET_APK" | awk '{print $1}')
elif command -v shasum &> /dev/null; then
    SHA256=$(shasum -a 256 "$TARGET_APK" | awk '{print $1}')
else
    SHA256="Could not compute (sha256sum/shasum not found)"
fi

echo ""
echo "============================================================"
echo "🎉 ASTRACK Release Build Successful!"
echo "Version:     $VERSION"
echo "Output APK:  $TARGET_APK"
echo "SHA-256:     $SHA256"
echo "Symbols Dir: build/symbols/"
echo "============================================================"
