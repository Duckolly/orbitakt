import 'package:flutter/services.dart';
import '../models/battery_session.dart';

class BatteryService {
  static const channel = MethodChannel('dvizh/battery');
  static Future<BatterySnapshot> snapshot() async {
    final value = await channel.invokeMapMethod<dynamic, dynamic>('snapshot');
    if (value == null) throw const FormatException('Снимок недоступен');
    return BatterySnapshot(value);
  }

  static Future<bool> settings(String method) async =>
      await channel.invokeMethod<bool>(method) ?? false;
}
