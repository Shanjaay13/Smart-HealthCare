#!/bin/bash
set -e
cd /Users/shanjaay/my_sejahtera_ng

echo "Cleaning project..."
flutter clean || true

echo "Backing up Info.plist..."
cp ios/Runner/Info.plist /tmp/Info-backup.plist || true

echo "Re-creating iOS platform directory..."
# Nuke everything inside iOS except the un-deletable .DS_Store file
find ios -mindepth 1 -not -name '.DS_Store' -delete || true

flutter create --platforms=ios .

echo "Restoring Info.plist..."
if [ -f /tmp/Info-backup.plist ]; then
    cp /tmp/Info-backup.plist ios/Runner/Info.plist
fi

echo "Generating Podfile..."
flutter build ios --config-only || true

echo "Setting iOS 13.0 Platform..."
sed -i '' "s/# platform :ios, '12.0'/platform :ios, '13.0'/g" ios/Podfile || true
sed -i '' "s/# platform :ios, '11.0'/platform :ios, '13.0'/g" ios/Podfile || true

echo "Installing Pods..."
flutter pub get
cd ios
pod install --repo-update
cd ..

echo "Building iOS App (Unsigned)..."
flutter build ios --release --no-codesign

echo "Packaging into IPA format for Sideloading..."
cd build/ios/iphoneos
mkdir -p Payload
cp -r Runner.app Payload/
zip -rq ../../../ios_app.ipa Payload
rm -rf Payload

echo "============================================="
echo "✅ SUCCESS! Your unsigned IPA is ready!"
echo "File location: /Users/shanjaay/my_sejahtera_ng/ios_app.ipa"
echo "You can now install this file using AltStore or Sideloadly."
