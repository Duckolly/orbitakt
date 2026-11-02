import 'dart:convert';
import 'package:flutter/services.dart';

class SkyCity {
  SkyCity({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  }) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        name.trim().isEmpty ||
        name.length > 80) {
      throw const FormatException('Invalid city');
    }
  }
  factory SkyCity.fromJson(Map<String, dynamic> data) => SkyCity(
    id: data['id'] as int,
    name: data['name'] as String,
    country: data['country'] as String,
    latitude: (data['lat'] as num).toDouble(),
    longitude: (data['lon'] as num).toDouble(),
  );
  final int id;
  final String name, country;
  final double latitude, longitude;
  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'lat': latitude,
    'lon': longitude,
  };
}

class SkyStar {
  const SkyStar(this.id, this.ra, this.dec, this.magnitude, this.name);
  final int id;
  final double ra, dec, magnitude;
  final String name;
}

class SkyFigure {
  const SkyFigure(this.name, this.paths);
  final String name;
  final List<List<int>> paths;
  Iterable<int> get ids => paths.expand((p) => p).toSet();
}

class SkyCatalog {
  const SkyCatalog(this.stars, this.figures, this.cities);
  final List<SkyStar> stars;
  final List<SkyFigure> figures;
  final List<SkyCity> cities;
  static Future<SkyCatalog> load() async {
    final data = await Future.wait(
      [
        'stars',
        'figures',
        'cities',
      ].map((n) => rootBundle.loadString('assets/sky/$n.json')),
    );
    final rawStars =
        (jsonDecode(data[0]) as Map<String, dynamic>)['stars'] as List;
    final stars = rawStars
        .map((raw) {
          final s = raw as Map<String, dynamic>;
          final star = SkyStar(
            s['id'] as int,
            (s['ra'] as num).toDouble(),
            (s['dec'] as num).toDouble(),
            (s['mag'] as num).toDouble(),
            s['name'] as String,
          );
          if (![star.ra, star.dec, star.magnitude].every((v) => v.isFinite) ||
              star.ra < 0 ||
              star.ra >= 360 ||
              star.dec.abs() > 90) {
            throw const FormatException('Invalid star');
          }
          return star;
        })
        .toList(growable: false);
    final ids = stars.map((s) => s.id).toSet();
    if (ids.length != stars.length || stars.isEmpty) {
      throw const FormatException('Invalid catalogue');
    }
    final figures =
        ((jsonDecode(data[1]) as Map<String, dynamic>)['figures'] as List)
            .map((raw) {
              final f = raw as Map<String, dynamic>;
              final paths = (f['paths'] as List)
                  .map((p) => (p as List).cast<int>())
                  .toList(growable: false);
              if (paths.any(
                (p) => p.length < 2 || p.any((id) => !ids.contains(id)),
              )) {
                throw const FormatException('Unknown figure star');
              }
              return SkyFigure(f['name'] as String, paths);
            })
            .toList(growable: false);
    final cities =
        ((jsonDecode(data[2]) as Map<String, dynamic>)['cities'] as List)
            .map((raw) => SkyCity.fromJson(raw as Map<String, dynamic>))
            .toList(growable: false);
    return SkyCatalog(stars, figures, cities);
  }
}
