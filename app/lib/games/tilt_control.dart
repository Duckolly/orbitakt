import 'snake_game.dart';

class TiltControl {
  int samples = 0;
  double _baseX = 0, _baseY = 0, _x = 0, _y = 0;
  double? _previousX, _previousY;
  int? _rotation;
  bool _latched = false;
  bool get calibrated => samples >= 15;
  void reset() {
    samples = 0;
    _baseX = 0;
    _baseY = 0;
    _previousX = null;
    _previousY = null;
    _latched = false;
    _rotation = null;
  }

  SnakeDirection? add(double x, double y, double z, int rotation) {
    if (![x, y, z].every((v) => v.isFinite) ||
        z.abs() < 4 ||
        x * x + y * y + z * z < 36 ||
        x * x + y * y + z * z > 225) {
      reset();
      return null;
    }
    if (_rotation != null && rotation != _rotation) reset();
    _rotation = rotation;
    if (!calibrated) {
      if (_previousX != null &&
          ((x - _previousX!).abs() > .7 || (y - _previousY!).abs() > .7)) {
        samples = 0;
        _baseX = 0;
        _baseY = 0;
      }
      _previousX = x;
      _previousY = y;
      _baseX += x;
      _baseY += y;
      samples++;
      if (calibrated) {
        _baseX /= samples;
        _baseY /= samples;
        _x = 0;
        _y = 0;
      }
      return null;
    }
    _x += .35 * (x - _baseX - _x);
    _y += .35 * (y - _baseY - _y);
    if (_x.abs() < 1 && _y.abs() < 1) _latched = false;
    if (_latched || (_x.abs() < 2.2 && _y.abs() < 2.2)) return null;
    _latched = true;
    return _x.abs() > _y.abs()
        ? (_x > 0 ? SnakeDirection.right : SnakeDirection.left)
        : (_y > 0 ? SnakeDirection.down : SnakeDirection.up);
  }
}
