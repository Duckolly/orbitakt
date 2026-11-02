#!/usr/bin/env python3
"""Check aapt dump permissions for the main or explicitly selected preview package."""
import argparse
import re
import sys
parser = argparse.ArgumentParser()
parser.add_argument('--package', choices=['com.duckolly.dvizh', 'com.duckolly.dvizh.preview'], default='com.duckolly.dvizh')
args = parser.parse_args()
expected = {
    'android.permission.ACTIVITY_RECOGNITION',
    'android.permission.POST_NOTIFICATIONS',
    'android.permission.FOREGROUND_SERVICE',
    'android.permission.FOREGROUND_SERVICE_HEALTH',
    args.package + '.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
}
actual = set(re.findall(r"uses-permission: name='([^']+)'", sys.stdin.read()))
if actual != expected:
    print('FAIL: unexpected=', sorted(actual-expected), 'missing=', sorted(expected-actual))
    sys.exit(1)
print('PASS: exact APK permission allowlist for', args.package)
