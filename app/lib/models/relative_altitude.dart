import 'dart:math' as math;

class RelativeAltitude {
  final _window = <double>[];
  int samples = 0;
  double _initialSum = 0;
  double? baseline, pressure;
  bool get calibrated => baseline != null;
  void reset() {
    _window.clear();
    samples = 0;
    _initialSum = 0;
    baseline = null;
    pressure = null;
  }

  bool add(double value) {
    if (!value.isFinite || value < 100 || value > 1200) return false;
    _window.add(value);
    if (_window.length > 5) _window.removeAt(0);
    pressure = _window.reduce((a, b) => a + b) / _window.length;
    if (baseline == null) {
      _initialSum += value;
      samples++;
      if (samples >= 10) baseline = _initialSum / samples;
    }
    return true;
  }

  double? get meters => baseline == null || pressure == null
      ? null
      : 44330 * (1 - math.pow(pressure! / baseline!, .190294957).toDouble());
}
