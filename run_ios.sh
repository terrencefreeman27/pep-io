#!/bin/bash
# Workaround for macOS 26 Tahoe code signing issue with Flutter
# Use this script instead of "flutter run" for iOS simulator

set -e

echo "🔧 Getting Flutter dependencies..."
flutter pub get

echo "🔨 Building with Xcode (automatic code signing for App Groups)..."
cd ios
pod install
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -sdk iphonesimulator \
  -configuration Debug \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=YES \
  CODE_SIGNING_ALLOWED=YES \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  build 2>&1 | tail -20

echo "📱 Installing app on simulator..."
# Find the correct Runner.app (not in Index.noindex)
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name 'Runner.app' -path '*/Build/Products/Debug-iphonesimulator/*' ! -path '*/Index.noindex/*' 2>/dev/null | head -1)
if [ -z "$APP_PATH" ]; then
  echo "❌ Could not find Runner.app"
  exit 1
fi
echo "Found app at: $APP_PATH"
xcrun simctl install booted "$APP_PATH"

echo "🚀 Launching app..."
xcrun simctl launch booted com.example.pepIo

echo "✅ App launched successfully!"
echo ""
echo "To see logs, run: flutter logs"
