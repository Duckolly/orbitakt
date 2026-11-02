#!/usr/bin/env bash
# Fail-closed local gate. PASS requires static checks, analyze, tests, fresh APK and aapt.
set -euo pipefail
export CI=true BOT=true FLUTTER_SUPPRESS_ANALYTICS=true DART_SUPPRESS_ANALYTICS=true
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$APP_ROOT"
MODE="${1:-full}"
case "$MODE" in full|--strict|--static-only|--skip-build) ;; *) echo 'Usage: release_gate.sh [--strict|--static-only|--skip-build]' >&2; exit 2;; esac
python3 ../tools/static_check.py
if [[ "$MODE" == '--static-only' ]]; then
  echo 'STATIC_ONLY: Flutter/build/permissions/device tests NOT_RUN; not a release PASS.'; exit 0
fi
if ! command -v flutter >/dev/null; then echo 'BLOCKED: Flutter SDK is missing. No release PASS.' >&2; exit 2; fi
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
if [[ "$MODE" == '--skip-build' ]]; then echo 'BLOCKED: build and merged permissions skipped. No release PASS.'; exit 2; fi
flutter build apk --debug --no-pub
(cd android && ./gradlew :app:testDebugUnitTest :app:lintDebug --no-daemon --max-workers=1)
APK='build/app/outputs/flutter-apk/app-debug.apk'
[[ -s "$APK" ]] || { echo 'FAIL: fresh APK absent'; exit 1; }
AAPT="$(command -v aapt || true)"
if [[ -z "$AAPT" ]]; then
  SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
  if [[ -n "$SDK" && -d "$SDK/build-tools" ]]; then AAPT="$(find "$SDK/build-tools" -name aapt -type f | sort -V | tail -1)"; fi
fi
[[ -n "$AAPT" && -x "$AAPT" ]] || { echo 'BLOCKED: aapt absent; merged permissions unverified'; exit 2; }
PERMS="$("$AAPT" dump permissions "$APK")" || { echo 'FAIL: aapt could not read APK'; exit 1; }
[[ -n "$PERMS" ]] || { echo 'FAIL: empty aapt output'; exit 1; }
printf '%s\n' "$PERMS" | python3 ../tools/check_permissions.py
for PERMISSION in INTERNET ACCESS_NETWORK_STATE ACCESS_WIFI_STATE ACCESS_FINE_LOCATION ACCESS_COARSE_LOCATION CAMERA RECORD_AUDIO READ_CONTACTS READ_CALENDAR WRITE_CALENDAR READ_SMS RECEIVE_SMS RECEIVE_BOOT_COMPLETED WAKE_LOCK VIBRATE; do
  if grep -q "android.permission.$PERMISSION'" <<< "$PERMS"; then echo "FAIL: forbidden $PERMISSION"; exit 1; fi
done
for REQUIRED in FOREGROUND_SERVICE FOREGROUND_SERVICE_HEALTH; do
 grep -q "android.permission.$REQUIRED'" <<< "$PERMS" || { echo "FAIL: missing $REQUIRED"; exit 1; }
done
if grep -q 'com.google.android.gms.permission.AD_ID' <<< "$PERMS"; then echo 'FAIL: advertising identifier permission'; exit 1; fi
python3 - "$APK" <<'PY'
import hashlib,sys
from pathlib import Path
print('DEBUG_APK_SHA256='+hashlib.sha256(Path(sys.argv[1]).read_bytes()).hexdigest())
PY
echo 'PASS_DEBUG_BUILD: device tests, battery, release signing and store approval still require separate checks.'
