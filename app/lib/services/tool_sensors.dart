import 'dart:async';
import 'package:flutter/services.dart';

class ToolSensors {
  static Future<bool> supported(String mode) async =>
      (await MethodChannel(
        'dvizh/$mode',
      ).invokeMapMethod<String, dynamic>('status'))?['supported'] ==
      true;
  static Stream<Map<dynamic, dynamic>> readings(
    String mode, [
    Map<String, Object?>? arguments,
  ]) => EventChannel(
    'dvizh/$mode/events',
  ).receiveBroadcastStream(arguments).map((e) => e as Map);
}

/// Serializes changes and rejects events from older subscriptions immediately.
class ToolSensorLease {
  StreamSubscription<Map<dynamic, dynamic>>? _subscription;
  Future<void> _operations = Future<void>.value();
  int _generation = 0;
  void start(
    String mode,
    void Function(Map<dynamic, dynamic>) receive,
    void Function() failed, {
    Map<String, Object?>? arguments,
  }) {
    final generation = ++_generation;
    _operations = _operations
        .then((_) async {
          final old = _subscription;
          _subscription = null;
          await old?.cancel();
          if (generation != _generation) return;
          _subscription = ToolSensors.readings(mode, arguments).listen(
            (data) {
              if (generation == _generation) receive(data);
            },
            onError: (Object error) {
              if (generation == _generation) failed();
            },
            onDone: () {
              if (generation == _generation) failed();
            },
          );
        })
        .catchError((Object error) {
          if (generation == _generation) failed();
        });
  }

  void stop() {
    ++_generation;
    _operations = _operations
        .then((_) async {
          final old = _subscription;
          _subscription = null;
          await old?.cancel();
        })
        .catchError((Object _) {});
  }
}
