import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/services/hardware_workout_sensor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'shared totals count once, exclude pause, cancel native stream',
    () async {
      const name = 'dvizh/daily/events';
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(name), (call) async {
            calls.add(call.method);
            return null;
          });
      Future<void> emit(int total, {bool syncing = false}) async {
        ServicesBinding.instance.channelBuffers.push(
          name,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'supported': true,
            'enabled': true,
            'running': true,
            'totalRecorded': total,
            'syncPending': syncing,
          }),
          (_) {},
        );
        await Future<void>.delayed(Duration.zero);
      }

      final sensor = HardwareWorkoutSensor();
      final steps = <int>[];
      sensor.start(steps.add);
      await Future<void>.delayed(Duration.zero);
      await emit(80, syncing: true);
      await emit(100);
      await emit(105);
      await emit(105);
      expect(sensor.steps, 5);
      await sensor.stop();
      await Future<void>.delayed(Duration.zero);
      expect(calls, contains('cancel'));
      sensor.start(steps.add);
      await Future<void>.delayed(Duration.zero);
      await emit(120, syncing: true);
      await emit(120);
      await emit(122);
      expect(sensor.steps, 7);
      await sensor.stop();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel(name), null);
    },
  );
}
