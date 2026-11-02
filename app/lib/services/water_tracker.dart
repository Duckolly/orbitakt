import 'package:flutter/services.dart';

class WaterDay {
  final String day;
  final int glasses;
  WaterDay(Map<dynamic, dynamic> map)
    : day = map['day'] as String,
      glasses = map['glasses'] as int;
  int get millilitres => glasses * 200;
}

class WaterStatus {
  final String today;
  final int glasses;
  final List<WaterDay> history;
  WaterStatus(Map<dynamic, dynamic> map)
    : today = map['today'] as String,
      glasses = map['glasses'] as int,
      history = (map['history'] as List)
          .map((e) => WaterDay(e as Map))
          .toList();
  int get millilitres => glasses * 200;
}

class WaterTracker {
  static const channel = MethodChannel('dvizh/water');
  static Future<WaterStatus> status() async =>
      WaterStatus((await channel.invokeMapMethod<String, dynamic>('status'))!);
  static Future<WaterStatus> change(int delta) async {
    if (delta != 1 && delta != -1) throw ArgumentError.value(delta);
    return WaterStatus(
      (await channel.invokeMapMethod<String, dynamic>('change', {
        'delta': delta,
      }))!,
    );
  }

  static Future<void> clear() async {
    await channel.invokeMethod<void>('clear');
  }

  static Future<bool> pinWidget() async =>
      await channel.invokeMethod<bool>('pinWidget') ?? false;
}
