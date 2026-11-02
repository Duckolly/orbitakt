import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/games/tilt_control.dart';
import 'package:dvizh/games/snake_game.dart';

void main() {
  TiltControl calibrated() {
    final c = TiltControl();
    for (var i = 0; i < 15; i++) {
      c.add(0, 0, 9.8, 0);
    }
    return c;
  }

  SnakeDirection? feed(TiltControl c, double x, double y) {
    SnakeDirection? result;
    for (var i = 0; i < 12; i++) {
      result = c.add(x, y, 9.8, 0) ?? result;
    }
    return result;
  }

  test('stable calibration and dead zone reject accidental turns', () {
    final c = calibrated();
    expect(c.calibrated, isTrue);
    expect(feed(c, .5, -.5), isNull);
    c.reset();
    for (var i = 0; i < 20; i++) {
      c.add(i.isEven ? 2 : -2, 0, 9.8, 0);
    }
    expect(c.calibrated, isFalse);
  });
  test('one turn per tilt requires neutral before next direction', () {
    final c = calibrated();
    expect(feed(c, 4, 0), SnakeDirection.right);
    expect(feed(c, 0, -4), isNull);
    expect(feed(c, 0, 0), isNull);
    expect(feed(c, 0, -4), SnakeDirection.up);
  });
  test('display rotation and invalid gravity force fresh calibration', () {
    final c = calibrated();
    c.add(0, 0, 9.8, 1);
    expect(c.calibrated, isFalse);
    c.add(double.nan, 0, 9.8, 1);
    expect(c.samples, 0);
    c.add(0, 9.8, 0, 1);
    expect(c.samples, 0);
  });
}
