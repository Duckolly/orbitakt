import 'dart:math' as math;

class HorizontalPosition {
  const HorizontalPosition(this.azimuth, this.altitude);
  final double azimuth, altitude;
}

/// Approximate, geometric sky. UTC substitutes UT1; no refraction or aberration.
class SkyMath {
  static const _rad = math.pi / 180;
  static double wrap(double angle) => ((angle % 360) + 360) % 360;
  static double julianDate(DateTime instant) =>
      instant.toUtc().microsecondsSinceEpoch / 86400000000 + 2440587.5;
  static void validateDate(DateTime instant) {
    if (instant.toUtc().year < 2000 || instant.toUtc().year > 2100) {
      throw ArgumentError('Supported sky dates: 2000–2100');
    }
  }

  static double siderealDegrees(DateTime instant, double longitude) {
    validateDate(instant);
    final d = julianDate(instant) - 2451545;
    final t = d / 36525;
    return wrap(
      (18.697375 + 24.065709824279 * d + .0000258 * t * t) * 15 + longitude,
    );
  }

  /// IAU 1976 J2000-to-date precession; result is RA/Dec in degrees.
  static math.Point<double> precess(double ra, double dec, DateTime instant) {
    validateDate(instant);
    final t = (julianDate(instant) - 2451545) / 36525;
    final zeta =
        (2306.2181 * t + .30188 * t * t + .017998 * t * t * t) / 3600 * _rad;
    final z =
        (2306.2181 * t + 1.09468 * t * t + .018203 * t * t * t) / 3600 * _rad;
    final theta =
        (2004.3109 * t - .42665 * t * t - .041833 * t * t * t) / 3600 * _rad;
    final a = ra * _rad + zeta, d = dec * _rad;
    final x = math.cos(d) * math.sin(a);
    final y =
        math.cos(theta) * math.cos(d) * math.cos(a) -
        math.sin(theta) * math.sin(d);
    final q =
        math.sin(theta) * math.cos(d) * math.cos(a) +
        math.cos(theta) * math.sin(d);
    return math.Point(
      wrap((math.atan2(x, y) + z) / _rad),
      math.asin(q.clamp(-1, 1)) / _rad,
    );
  }

  static HorizontalPosition horizontal(
    double raOfDate,
    double decOfDate,
    double latitude,
    double localSiderealDegrees,
  ) {
    if (![
          raOfDate,
          decOfDate,
          latitude,
          localSiderealDegrees,
        ].every((v) => v.isFinite) ||
        decOfDate.abs() > 90 ||
        latitude.abs() > 90) {
      throw ArgumentError('Invalid sky coordinates');
    }
    final h = (localSiderealDegrees - raOfDate) * _rad;
    final d = decOfDate * _rad, lat = latitude * _rad;
    final east = -math.cos(d) * math.sin(h);
    final north =
        math.sin(d) * math.cos(lat) - math.cos(d) * math.cos(h) * math.sin(lat);
    final up =
        math.sin(d) * math.sin(lat) + math.cos(d) * math.cos(h) * math.cos(lat);
    return HorizontalPosition(
      wrap(math.atan2(east, north) / _rad),
      math.asin(up.clamp(-1, 1)) / _rad,
    );
  }

  /// All-sky chart viewed from inside the celestial sphere: east is on the left.
  static math.Point<double>? project(
    HorizontalPosition position,
    double topAzimuth,
  ) {
    if (position.altitude < 0) return null;
    final r = (90 - position.altitude) / 90;
    final a = (position.azimuth - topAzimuth) * _rad;
    return math.Point(-math.sin(a) * r, -math.cos(a) * r);
  }
}
