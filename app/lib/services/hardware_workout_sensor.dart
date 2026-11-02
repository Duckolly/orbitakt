import 'dart:async';
import 'daily_tracker.dart';
import 'sensor_service.dart';

/// Observes the same committed daily counter. Never adds workout steps to it.
class HardwareWorkoutSensor extends SensorService {
  StreamSubscription<DailyStatus>? _subscription;
  int _steps = 0;
  int? _baseline;
  bool _active = false;
  @override
  int get steps => _steps;
  @override
  bool get isActive => _active;
  @override
  void start(void Function(int) onStep, {void Function(Object)? onError}) {
    if (_active) return;
    _active = true;
    _baseline = null;
    _subscription = DailyTracker.events.listen(
      (status) {
        if (!_active) return;
        if (!status.active) {
          _active = false;
          onError?.call(StateError('Дневной шагомер остановлен'));
          return;
        }
        if (status.syncPending) {
          _baseline = null;
          return;
        }
        final previous = _baseline;
        _baseline = status.totalRecorded;
        if (previous != null && status.totalRecorded >= previous) {
          _steps += status.totalRecorded - previous;
          onStep(_steps);
        }
      },
      onError: (Object error) {
        _active = false;
        onError?.call(error);
      },
    );
  }

  @override
  Future<void> stop() async {
    _active = false;
    final subscription = _subscription;
    _subscription = null;
    await subscription?.cancel();
  }

  @override
  void reset() {
    _steps = 0;
    _baseline = null;
  }

  @override
  void dispose() {
    unawaited(stop());
  }
}
