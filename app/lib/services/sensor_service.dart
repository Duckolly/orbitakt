import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Software estimate from dynamic acceleration, not an accuracy guarantee.
class SensorService {
  SensorService({Stream<UserAccelerometerEvent> Function()? events})
    : _events =
          events ??
          (() => userAccelerometerEventStream(
            samplingPeriod: const Duration(milliseconds: 50),
          ));

  final Stream<UserAccelerometerEvent> Function() _events;
  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final Stopwatch _clock = Stopwatch();
  int _steps = 0;
  int? _lastStepMs;
  double _lastMagnitude = 0;
  bool _isActive = false;
  int get steps => _steps;
  bool get isActive => _isActive;

  void start(void Function(int) onStep, {void Function(Object)? onError}) {
    if (_isActive) return;
    _isActive = true;
    _lastMagnitude = 0;
    _lastStepMs = null;
    _clock.start();
    try {
      _subscription = _events().listen(
        (event) {
          if (!_isActive) return;
          final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );
          if (!magnitude.isFinite) return;
          final now = _clock.elapsedMilliseconds;
          if (magnitude > 1.3 &&
              _lastMagnitude <= 1.3 &&
              (_lastStepMs == null || now - _lastStepMs! >= 300)) {
            _steps++;
            _lastStepMs = now;
            onStep(_steps);
          }
          _lastMagnitude = magnitude;
        },
        onError: (Object error) {
          _isActive = false;
          _clock.stop();
          onError?.call(error);
        },
        cancelOnError: true,
      );
    } catch (error) {
      _isActive = false;
      _clock.stop();
      rethrow;
    }
  }

  Future<void> stop() async {
    _isActive = false;
    _clock.stop();
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  void reset() {
    _steps = 0;
    _lastMagnitude = 0;
    _lastStepMs = null;
    _clock.reset();
  }

  void dispose() {
    unawaited(stop());
  }
}
