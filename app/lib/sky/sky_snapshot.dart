import 'sky_catalog.dart';
import 'sky_math.dart';

class SkySnapshot {
  SkySnapshot(SkyCatalog catalog, SkyCity city, DateTime utc) {
    SkyMath.validateDate(utc);
    final lst = SkyMath.siderealDegrees(utc, city.longitude);
    for (final star in catalog.stars) {
      final p = SkyMath.precess(star.ra, star.dec, utc);
      positions[star.id] = SkyMath.horizontal(p.x, p.y, city.latitude, lst);
    }
  }
  final positions = <int, HorizontalPosition>{};
  int above(SkyFigure f) =>
      f.ids.where((id) => (positions[id]?.altitude ?? -90) >= 0).length;
}
