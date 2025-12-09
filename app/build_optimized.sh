#!/bin/bash
# Crescent Gate - Optimized Release Build Script
# This builds the smallest, fastest APK possible

echo "🚀 Building optimized release APK..."

# Clean first
flutter clean

# Build with all optimizations
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  --target-platform android-arm64 \
  --split-per-abi

echo "✅ Build complete!"
echo "📦 APK locations:"
echo "   - build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "   - build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
echo "   - build/app/outputs/flutter-apk/app-x86_64-release.apk"
