#!/usr/bin/env python3
"""Packaging checks; deliberately not a Dart compiler or Android build proof."""
import ast
import json
import re
import sys
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / 'app'
errors = []
checks = []

def require(condition, message):
    (checks if condition else errors).append(message)

class Page(HTMLParser):
    def __init__(self):
        super().__init__(); self.resources = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ('img', 'script') and attrs.get('src'): self.resources.append(attrs['src'])
        if tag == 'link' and attrs.get('href'): self.resources.append(attrs['href'])

for path in (APP / 'android').rglob('*.xml'):
    try: ET.parse(path)
    except ET.ParseError as error: errors.append(f'Invalid XML: {path.relative_to(ROOT)}: {error}')
for path in (APP / 'lib').rglob('*.dart'):
    text = path.read_text()
    for target in re.findall(r"import\s+['\"]([^'\"]+)['\"]", text):
        if not target.startswith(('package:', 'dart:')):
            require((path.parent / target).is_file(), f'Dart relative import: {path.name}: {target}')
        require(not target.startswith(('package:http/', 'package:dio/', 'package:firebase', 'package:google_mobile_ads')), f'No network/telemetry import: {path.name}')
    require('Colors.orange' not in text, f'Latest palette: {path.name}')
ns = '{http://schemas.android.com/apk/res/android}'
manifest = ET.parse(APP / 'android/app/src/main/AndroidManifest.xml').getroot()
perms = {node.get(ns+'name') for node in manifest.findall('uses-permission') if node.get('{http://schemas.android.com/tools}node') != 'remove'}
require('android.permission.INTERNET' not in perms, 'No active source INTERNET permission (merged APK still unverified)')
require({'android.permission.FOREGROUND_SERVICE', 'android.permission.FOREGROUND_SERVICE_HEALTH'} <= perms, 'Daily health service permissions declared')
service = next((s for s in manifest.findall('application/service') if s.get(ns+'name')=='.DailyStepService'), None)
require(service is not None and service.get(ns+'exported')=='false' and service.get(ns+'foregroundServiceType')=='health', 'Non-exported health foreground service')
widget = next((w for w in manifest.findall('application/receiver') if w.get(ns+'name')=='.ProgressWidget'), None)
require(widget is not None and widget.get(ns+'exported')=='false', 'Widget receiver is private')
info=ET.parse(APP / 'android/app/src/main/res/xml/progress_widget_info.xml').getroot()
require(info.get(ns+'updatePeriodMillis')=='1800000' and info.get(ns+'widgetCategory')=='home_screen', 'Home widget uses system 30-minute updates')
require((APP / 'android/app/src/main/kotlin/com/duckolly/dvizh/WaterStore.kt').is_file(), 'Native water persistence included')
feature = manifest.find('uses-feature')
require(feature is not None and feature.get(ns+'required') == 'false', 'Accelerometer optional')
gradle = (APP / 'android/app/build.gradle').read_text()
activity = (APP / 'android/app/src/main/kotlin/com/duckolly/dvizh/MainActivity.kt').read_text()
require('com.duckolly.dvizh' in gradle and 'package com.duckolly.dvizh' in activity, 'Android namespace and MainActivity consistent')
require('userAccelerometerEventStream' in (APP / 'lib/services/sensor_service.dart').read_text(), 'Dynamic acceleration input')
for path in (ROOT / 'site').glob('*.html'):
    text = path.read_text(); page = Page(); page.feed(text)
    for link in page.resources:
        if link.startswith(('https:', 'http:', '#', 'data:', '/')): continue
        require((path.parent / link.split('?')[0]).is_file(), f'Local site resource: {link}')
    for payload in re.findall(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>', text, re.S):
        try: json.loads(payload)
        except json.JSONDecodeError as error: errors.append(f'Invalid JSON-LD {path.name}: {error}')
try: json.loads((ROOT / 'site/site.webmanifest').read_text())
except json.JSONDecodeError as error: errors.append(f'Invalid webmanifest: {error}')
for path in (ROOT / 'branding').glob('*.py'):
    try: ast.parse(path.read_text())
    except SyntaxError as error: errors.append(f'Invalid Python {path.name}: {error}')
print(json.dumps({'checks_passed':len(checks), 'errors':errors, 'flutter_build':'NOT_CHECKED_BY_THIS_SCRIPT', 'device_tests':'NOT_RUN'}, ensure_ascii=False, indent=2))
sys.exit(1 if errors else 0)
