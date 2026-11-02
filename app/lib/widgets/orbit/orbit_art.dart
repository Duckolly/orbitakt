import 'package:flutter/material.dart';

/// Static, resolution-independent art: no animation loop or sensor subscription.
class OrbitArt extends StatelessWidget {
  const OrbitArt({super.key, this.water = false, this.progress = .0});
  final bool water;
  final double progress;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: water ? 160 : 94,
      width: double.infinity,
      child: CustomPaint(
        painter: _OrbitPainter(
          water,
          progress,
          Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  _OrbitPainter(this.water, this.progress, this.dark);
  final bool water, dark;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    if (water) {
      final rect = Rect.fromLTWH(w * .31, 10, w * .33, h - 25);
      final glass = Path()
        ..moveTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right - 12, rect.bottom)
        ..quadraticBezierTo(
          rect.center.dx,
          rect.bottom + 8,
          rect.left + 12,
          rect.bottom,
        )
        ..close();
      canvas.save();
      canvas.clipPath(glass);
      canvas.drawRect(
        rect,
        Paint()..color = const Color(0xFF71CCD5).withValues(alpha: .16),
      );
      final level = rect.bottom - rect.height * progress.clamp(0, 1);
      canvas.drawRect(
        Rect.fromLTRB(rect.left, level, rect.right, rect.bottom + 8),
        Paint()..color = const Color(0xFF46AEBF).withValues(alpha: .65),
      );
      canvas.restore();
      canvas.drawPath(
        glass,
        Paint()
          ..color = dark ? const Color(0xFFA5E2E8) : const Color(0xFF397C90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      _pebble(canvas, Offset(w * .77, h * .7), 24);
    } else {
      final path = Path()
        ..moveTo(12, h - 15)
        ..cubicTo(w * .04, -5, w * .58, h + 35, w * .60, h * .46)
        ..cubicTo(w * .60, 4, w * .88, h * .65, w - 12, 13);
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xFF564164) : const Color(0xFFE1C3EF)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 16,
      );
      final metric = path.computeMetrics().first;
      final p = progress.clamp(0.0, 1.0);
      canvas.drawPath(
        metric.extractPath(0, metric.length * p),
        Paint()
          ..color = const Color(0xFF9653BF)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 16,
      );
      final point =
          metric.getTangentForOffset(metric.length * p)?.position ??
          Offset.zero;
      _pebble(
        canvas,
        Offset(point.dx.clamp(24, w - 24), (point.dy - 24).clamp(26, h - 28)),
        19,
      );
    }
  }

  void _pebble(Canvas c, Offset at, double r) {
    c.drawOval(
      Rect.fromCenter(center: at + Offset(0, r + 5), width: r * 1.8, height: 7),
      Paint()..color = Colors.black.withValues(alpha: .09),
    );
    final body = Rect.fromCenter(center: at, width: r * 1.7, height: r * 2);
    c.drawRRect(
      RRect.fromRectAndCorners(
        body,
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
        bottomLeft: Radius.circular(r * .7),
        bottomRight: Radius.circular(r * .7),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB37ADC), Color(0xFF612280)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(body),
    );
    for (final dx in [-r * .28, r * .28]) {
      c.drawOval(
        Rect.fromCenter(
          center: at + Offset(dx, -r * .15),
          width: r * .35,
          height: r * .46,
        ),
        Paint()..color = Colors.white,
      );
      c.drawCircle(
        at + Offset(dx + 1, -r * .12),
        r * .10,
        Paint()..color = const Color(0xFF302039),
      );
      c.drawLine(
        at + Offset(dx, r * .90),
        at + Offset(dx + 2, r * 1.12),
        Paint()
          ..color = const Color(0xFF55236C)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.water != water || old.progress != progress || old.dark != dark;
}
