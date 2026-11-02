import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dvizh/services/sensor_service.dart';

void main() {
  test(
    'a held acceleration is not counted repeatedly and stopped stream is ignored',
    () async {
      final events = StreamController<UserAccelerometerEvent>();
      final sensor = SensorService(events: () => events.stream);
      final steps = <int>[];
      sensor.start(steps.add);
      events.add(UserAccelerometerEvent(2, 0, 0, DateTime.now()));
      events.add(UserAccelerometerEvent(2, 0, 0, DateTime.now()));
      await Future<void>.delayed(Duration.zero);
      expect(steps, [1]);
      await sensor.stop();
      events.add(UserAccelerometerEvent(4, 0, 0, DateTime.now()));
      await Future<void>.delayed(Duration.zero);
      expect(steps, [1]);
      expect(sensor.isActive, false);
      await events.close();
    },
  );

  test('sensor error deactivates recording and reaches caller', () async {
    final events = StreamController<UserAccelerometerEvent>();
    final sensor = SensorService(events: () => events.stream);
    Object? failure;
    sensor.start((_) {}, onError: (error) => failure = error);
    events.addError(StateError('missing sensor'));
    await Future<void>.delayed(Duration.zero);
    expect(sensor.isActive, false);
    expect(failure, isA<StateError>());
    await sensor.stop();
    await events.close();
  });
}
