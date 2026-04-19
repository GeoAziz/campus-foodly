#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"

echo "Building Android release APK via Gradle..."
"$ANDROID_DIR/gradlew" -p "$ANDROID_DIR" assembleRelease --stacktrace

APK_PATH="$ROOT_DIR/build/app/outputs/flutter-apk/app-release.apk"
if [[ ! -f "$APK_PATH" ]]; then
  APK_PATH="$ROOT_DIR/build/app/outputs/apk/release/app-release.apk"
fi

if [[ ! -f "$APK_PATH" ]]; then
  echo "Release build finished but APK not found in expected output paths."
  exit 1
fi

echo "Release APK generated: $APK_PATH"