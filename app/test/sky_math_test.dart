import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/sky/sky_math.dart';
import 'package:dvizh/sky/sky_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('J2000 epoch, GMST and timezone independent instant', () {
    final t = DateTime.utc(2000, 1, 1, 12);
    expect(SkyMath.julianDate(t), 2451545);
    expect(SkyMath.siderealDegrees(t, 0), closeTo(280.460625, .000001));
    final p = SkyMath.precess(120, 45, t);
    expect(p.x, closeTo(120, 1e-9));
    expect(p.y, closeTo(45, 1e-9));
    final a = DateTime.parse('2026-11-02T20:00:00+04:00');
    expect(
      SkyMath.siderealDegrees(a, 50),
      SkyMath.siderealDegrees(a.toUtc(), 50),
    );
    expect(
      () => SkyMath.siderealDegrees(DateTime.utc(1999), 0),
      throwsArgumentError,
    );
  });
  test('analytic horizon, hemisphere, poles and chart orientation', () {
    final east = SkyMath.horizontal(90, 0, 0, 0);
    expect(east.azimuth, closeTo(90, 1e-8));
    expect(east.altitude, closeTo(0, 1e-8));
    final south = SkyMath.horizontal(0, 0, 45, 0);
    expect(south.azimuth, 180);
    expect(south.altitude, closeTo(45, 1e-8));
    final north = SkyMath.horizontal(0, 0, -45, 0);
    expect(north.azimuth, 0);
    expect(north.altitude, closeTo(45, 1e-8));
    expect(SkyMath.horizontal(40, 20, 90, 90).altitude, closeTo(20, 1e-8));
    expect(SkyMath.project(const HorizontalPosition(0, -1), 0), isNull);
    final e = SkyMath.project(const HorizontalPosition(90, 0), 0)!;
    expect(e.x, closeTo(-1, 1e-8));
    expect(e.y, closeTo(0, 1e-8));
    final top = SkyMath.project(const HorizontalPosition(90, 0), 90)!;
    expect(top.x, closeTo(0, 1e-8));
    expect(top.y, closeTo(-1, 1e-8));
  });
  test('48 independent Astropy reference positions, both hemispheres', () {
    final fixture =
        jsonDecode(File('test/fixtures/sky_reference.json').readAsStringSync())
            as Map;
    final cases = fixture['cases'] as List;
    expect(cases.length, 48);
    for (final raw in cases) {
      final c = raw as Map;
      final date = DateTime.parse(c['utc'] as String);
      final eq = SkyMath.precess(
        (c['ra'] as num).toDouble(),
        (c['dec'] as num).toDouble(),
        date,
      );
      final pos = SkyMath.horizontal(
        eq.x,
        eq.y,
        (c['lat'] as num).toDouble(),
        SkyMath.siderealDegrees(date, (c['lon'] as num).toDouble()),
      );
      const rad = math.pi / 180;
      final alt = (c['alt'] as num).toDouble();
      final az = (c['az'] as num).toDouble();
      final cosDistance =
          math.sin(pos.altitude * rad) * math.sin(alt * rad) +
          math.cos(pos.altitude * rad) *
              math.cos(alt * rad) *
              math.cos((pos.azimuth - az) * rad);
      final separation = math.acos(cosDistance.clamp(-1, 1)) / rad;
      expect(
        separation,
        lessThan(.15),
        reason: '${c['city']} ${c['utc']} HIP ${c['id']}',
      );
    }
  });
  test('embedded catalogue has valid stars, figures and cities', () async {
    final c = await SkyCatalog.load();
    expect(c.stars.length, 920);
    expect(c.figures.length, 14);
    expect(c.cities.length, 44);
    expect(c.cities.any((c) => c.name == 'Самара'), isTrue);
    expect(
      () =>
          SkyCity(id: 0, name: 'test', country: '', latitude: 91, longitude: 0),
      throwsFormatException,
    );
    expect(
      () => SkyCity(
        id: 0,
        name: 'test',
        country: '',
        latitude: 0,
        longitude: double.nan,
      ),
      throwsFormatException,
    );
  });
}
