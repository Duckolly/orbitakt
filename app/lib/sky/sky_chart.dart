import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'sky_catalog.dart';
import 'sky_snapshot.dart';
import 'sky_math.dart';

class SkyChart extends StatelessWidget {
  const SkyChart({
    super.key,
    required this.catalog,
    required this.snapshot,
    required this.top,
    this.figure,
    this.selectedStar,
    required this.onSelect,
  });
  final SkyCatalog catalog;
  final SkySnapshot snapshot;
  final double top;
  final String? figure;
  final int? selectedStar;
  final ValueChanged<int> onSelect;
  static Offset point(Size size, HorizontalPosition h, double top) {
    final p = SkyMath.project(h, top)!;
    final radius = size.shortestSide / 2 - 28;
    return Offset(
      size.width / 2 + p.x * radius,
      size.height / 2 + p.y * radius,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = Size.square(constraints.maxWidth);
      return Semantics(
        label:
            'Круговая карта: центр — зенит, край — горизонт. Восток слева. '
            'Подробности доступны в списках звёзд и созвездий ниже.',
        child: GestureDetector(
          onTapUp: (details) {
            int? nearest;
            var distance = 18.0;
            for (final star in catalog.stars) {
              final h = snapshot.positions[star.id]!;
              if (h.altitude < 0) continue;
              final d = (point(size, h, top) - details.localPosition).distance;
              if (d < distance) {
                nearest = star.id;
                distance = d;
              }
            }
            if (nearest != null) onSelect(nearest);
          },
          child: CustomPaint(
            size: size,
            painter: _SkyPainter(catalog, snapshot, top, figure, selectedStar),
          ),
        ),
      );
    },
  );
}

class _SkyPainter extends CustomPainter {
  const _SkyPainter(
    this.catalog,
    this.snapshot,
    this.top,
    this.figure,
    this.selectedStar,
  );
  final SkyCatalog catalog;
  final SkySnapshot snapshot;
  final double top;
  final String? figure;
  final int? selectedStar;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2),
        radius = size.shortestSide / 2 - 28;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)),
      Paint()..color = const Color(0xff0a1022),
    );
    final grid = Paint()
      ..color = const Color(0xff35435e)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final fraction in [1.0, 2 / 3, 1 / 3]) {
      canvas.drawCircle(center, radius * fraction, grid);
    }
    canvas.drawLine(
      center - Offset(radius, 0),
      center + Offset(radius, 0),
      grid,
    );
    canvas.drawLine(
      center - Offset(0, radius),
      center + Offset(0, radius),
      grid,
    );
    void label(String text, Offset at, Color color, {double font = 12}) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(color: color, fontSize: font, fontFamily: 'Roboto'),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width / 2);
      final x = (at.dx - painter.width / 2).clamp(
        2.0,
        math.max(2.0, size.width - painter.width - 2),
      );
      final y = (at.dy - painter.height / 2).clamp(
        2.0,
        math.max(2.0, size.height - painter.height - 2),
      );
      painter.paint(canvas, Offset(x.toDouble(), y.toDouble()));
    }

    for (var i = 0; i < 4; i++) {
      final a = (i * 90 - top) * math.pi / 180;
      label(
        ['С', 'В', 'Ю', 'З'][i],
        center + Offset(-math.sin(a), -math.cos(a)) * (radius + 15),
        const Color(0xffbfcde5),
        font: 15,
      );
    }
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius + 1)),
    );
    for (final f in catalog.figures) {
      final selected = f.name == figure;
      final pen = Paint()
        ..color = selected ? const Color(0xffffd181) : const Color(0xff536f9b)
        ..strokeWidth = selected ? 2 : 1;
      for (final path in f.paths) {
        for (var i = 1; i < path.length; i++) {
          final a = snapshot.positions[path[i - 1]]!,
              b = snapshot.positions[path[i]]!;
          if (a.altitude >= 0 && b.altitude >= 0) {
            canvas.drawLine(
              SkyChart.point(size, a, top),
              SkyChart.point(size, b, top),
              pen,
            );
          }
        }
      }
    }
    final named = <SkyStar>[];
    for (final star in catalog.stars) {
      final h = snapshot.positions[star.id]!;
      if (h.altitude < 0) continue;
      final at = SkyChart.point(size, h, top);
      final r = (2.8 - star.magnitude * .4).clamp(.65, 3.4);
      canvas.drawCircle(at, r, Paint()..color = const Color(0xffe2eaff));
      if (star.id == selectedStar) {
        canvas.drawCircle(
          at,
          8,
          Paint()
            ..color = const Color(0xffffd181)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      if (star.name.isNotEmpty &&
          (star.magnitude < .5 || star.id == selectedStar)) {
        named.add(star);
      }
    }
    canvas.restore();
    for (final s in named.take(6)) {
      label(
        s.name,
        SkyChart.point(size, snapshot.positions[s.id]!, top) +
            const Offset(0, 13),
        const Color(0xffa7c4f2),
        font: 10,
      );
    }
    label(
      'Зенит',
      center + const Offset(0, -10),
      const Color(0xff687b9b),
      font: 10,
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) =>
      old.snapshot != snapshot ||
      old.top != top ||
      old.figure != figure ||
      old.selectedStar != selectedStar;
}
