#!/usr/bin/env bash
set -euo pipefail
export CI=true BOT=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo 'Flutter 3.35.7 is required in PATH.' >&2; exit 2; }
VERSION=$(flutter --version --machine | python3 -c 'import sys,json; print(json.load(sys.stdin)["frameworkVersion"])')
[[ "$VERSION" == '3.35.7' ]] || { echo "Expected Flutter 3.35.7, found $VERSION" >&2; exit 2; }
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
flutter build apk --debug --no-pub
(cd android && ./gradlew :app:testDebugUnitTest :app:lintDebug --no-daemon --max-workers=1)
test -s build/app/outputs/flutter-apk/app-debug.apk
printf '%s\n' 'APK: build/app/outputs/flutter-apk/app-debug.apk'
