import 'package:flutter/services.dart';

class DeviceSensor {
  DeviceSensor(Map<dynamic, dynamic> map)
    : type = map['type'] as int,
      name = map['name'] as String,
      vendor = map['vendor'] as String,
      label = map['label'] as String,
      power = (map['power'] as num).toDouble(),
      resolution = (map['resolution'] as num).toDouble(),
      maxRange = (map['maxRange'] as num).toDouble(),
      minDelay = map['minDelay'] as int,
      wakeUp = map['wakeUp'] as bool;
  final int type, minDelay;
  final String name, vendor, label;
  final double power, resolution, maxRange;
  final bool wakeUp;
}

class DeviceSensors {
  static const channel = MethodChannel('dvizh/device');
  static Future<Map<dynamic, dynamic>> inventory() async =>
      (await channel.invokeMapMethod<dynamic, dynamic>('listSensors'))!;
}
