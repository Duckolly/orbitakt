import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyDay {
  DailyDay(Map<dynamic, dynamic> value)
    : day = value['day'] as String,
      steps = (value['steps'] as num).toInt(),
      estimated = value['estimated'] == true;
  final String day;
  final int steps;
  final bool estimated;
}

class DailyStatus {
  DailyStatus(Map<dynamic, dynamic> value)
    : supported = value['supported'] == true,
      enabled = value['enabled'] == true,
      running = value['running'] == true,
      permissionGranted = value['permissionGranted'] == true,
      notificationsAllowed = value['notificationsAllowed'] == true,
      totalRecorded = (value['totalRecorded'] as num?)?.toInt() ?? 0,
      todaySteps = (value['todaySteps'] as num?)?.toInt() ?? 0,
      gaps = (value['gaps'] as num?)?.toInt() ?? 0,
      issue = value['issue'] as String? ?? '',
      syncPending = value['syncPending'] == true,
      history = (value['history'] as List? ?? [])
          .map((value) => DailyDay(value as Map))
          .toList();
  final bool supported,
      enabled,
      running,
      permissionGranted,
      notificationsAllowed;
  final bool syncPending;
  final int totalRecorded, todaySteps, gaps;
  final String issue;
  final List<DailyDay> history;
  bool get active => enabled && running;
}

class DailyTracker {
  static const channel = MethodChannel('dvizh/daily');
  static const _eventChannel = EventChannel('dvizh/daily/events');
  static final Stream<DailyStatus> events = _eventChannel
      .receiveBroadcastStream()
      .map((value) => DailyStatus(value as Map));

  static Future<DailyStatus> status() async {
    try {
      final value = await channel.invokeMapMethod<dynamic, dynamic>('status');
      return DailyStatus(value ?? {});
    } on MissingPluginException {
      return DailyStatus({}); // Unsupported platform or test runner.
    }
  }

  static Future<DailyStatus> enable() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('recordingEnabled') ?? true)) {
      throw StateError('Запись отключена в настройках.');
    }
    final current = await status();
    if (!current.supported) {
      throw StateError(
        'Нет системного счётчика шагов. Доступен режим тренировок.',
      );
    }
    if (!current.permissionGranted &&
        !(await Permission.activityRecognition.request()).isGranted) {
      throw StateError('Разрешите распознавание физической активности.');
    }
    if (!current.notificationsAllowed) {
      // User may decline: Android still exposes the active foreground service.
      await Permission.notification.request();
    }
    return DailyStatus(
      await channel.invokeMapMethod<dynamic, dynamic>('enable') ?? {},
    );
  }

  static Future<DailyStatus> disable() async {
    try {
      return DailyStatus(
        await channel.invokeMapMethod<dynamic, dynamic>('disable') ?? {},
      );
    } on MissingPluginException {
      return DailyStatus({});
    }
  }

  static Future<void> clear() async {
    try {
      await channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      /* No daily store on unsupported platforms. */
    }
  }
}
