# Eilbay Mobile — build recipes

# Build release APK
apk:
    fvm flutter build apk --release
    @echo ""
    @echo "APK: build/app/outputs/flutter-apk/app-release.apk"
    @du -h build/app/outputs/flutter-apk/app-release.apk
    open build/app/outputs/flutter-apk/

# Build release AAB
aab:
    fvm flutter build appbundle --release
    @echo ""
    @echo "AAB: build/app/outputs/bundle/release/app-release.aab"
    @du -h build/app/outputs/bundle/release/app-release.aab
    open build/app/outputs/bundle/release/

# Build both APK + AAB
release: clean deps apk aab

# Clean project
clean:
    fvm flutter clean

# Get dependencies
deps:
    fvm flutter pub get

# Run analyzer
analyze:
    fvm flutter analyze lib/

# Run app in debug
run:
    fvm flutter run

# Open APK folder
open-apk:
    open build/app/outputs/flutter-apk/

# Open AAB folder
open-aab:
    open build/app/outputs/bundle/release/
