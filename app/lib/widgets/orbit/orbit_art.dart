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
      _drawMascot(canvas, Offset(w * .77, h * .7), 24);
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
      _drawMascot(
        canvas,
        Offset(point.dx.clamp(24, w - 24), (point.dy - 24).clamp(26, h - 28)),
        19,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) =>
      old.water != water || old.progress != progress || old.dark != dark;
}

void _drawMascot(Canvas c, Offset at, double r) {
  final purple = Paint()
    ..shader = const LinearGradient(
      colors: [Color(0xFFB87BE2), Color(0xFF6D3193)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromCenter(center: at, width: r * 3, height: r * 3));
  final dark = Paint()..color = const Color(0xFF4D2069);
  c.drawOval(
    Rect.fromCenter(
      center: at + Offset(0, r * 1.03),
      width: r * 1.7,
      height: r * .22,
    ),
    Paint()..color = Colors.black.withValues(alpha: .09),
  );
  // Curled tail behind the body; triangular ears make the silhouette feline.
  final tail = Path()
    ..moveTo(at.dx + r * .4, at.dy + r * .7)
    ..cubicTo(
      at.dx + r * 1.4,
      at.dy + r * .7,
      at.dx + r * 1.4,
      at.dy - r * .55,
      at.dx + r * .98,
      at.dy - r * .46,
    );
  c.drawPath(
    tail,
    Paint()
      ..color = const Color(0xFF8D46B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .24
      ..strokeCap = StrokeCap.round,
  );
  c.drawOval(
    Rect.fromCenter(
      center: at + Offset(0, r * .43),
      width: r * 1.22,
      height: r * 1.18,
    ),
    purple,
  );
  for (final sign in [-1.0, 1.0]) {
    final ear = Path()
      ..moveTo(at.dx + sign * r * .12, at.dy - r * .78)
      ..lineTo(at.dx + sign * r * .64, at.dy - r * 1.25)
      ..lineTo(at.dx + sign * r * .73, at.dy - r * .3)
      ..close();
    c.drawPath(ear, purple);
    final inner = Path()
      ..moveTo(at.dx + sign * r * .34, at.dy - r * .76)
      ..lineTo(at.dx + sign * r * .57, at.dy - r * 1.03)
      ..lineTo(at.dx + sign * r * .61, at.dy - r * .55)
      ..close();
    c.drawPath(inner, Paint()..color = const Color(0xFFE9A7D4));
  }
  c.drawOval(
    Rect.fromCenter(
      center: at + Offset(0, -r * .35),
      width: r * 1.48,
      height: r * 1.23,
    ),
    purple,
  );
  for (final sign in [-1.0, 1.0]) {
    final eye = at + Offset(sign * r * .29, -r * .4);
    c.drawOval(
      Rect.fromCenter(center: eye, width: r * .31, height: r * .39),
      Paint()..color = Colors.white,
    );
    c.drawOval(
      Rect.fromCenter(
        center: eye + Offset(r * .03, 0),
        width: r * .12,
        height: r * .28,
      ),
      dark,
    );
    c.drawOval(
      Rect.fromCenter(
        center: at + Offset(sign * r * .31, r * .93),
        width: r * .4,
        height: r * .27,
      ),
      dark,
    );
    for (final dy in [-.06, .12]) {
      c.drawLine(
        at + Offset(sign * r * .42, r * dy),
        at + Offset(sign * r * .92, r * (dy - .06)),
        Paint()
          ..color = const Color(0xFFEBCBFA)
          ..strokeWidth = r * .045
          ..strokeCap = StrokeCap.round,
      );
    }
  }
  final nose = Path()
    ..moveTo(at.dx - r * .1, at.dy - r * .15)
    ..lineTo(at.dx + r * .1, at.dy - r * .15)
    ..lineTo(at.dx, at.dy - r * .02)
    ..close();
  c.drawPath(nose, Paint()..color = const Color(0xFFFFC6DD));
  c.drawLine(
    at + Offset(0, -r * .02),
    at + Offset(0, r * .1),
    Paint()
      ..color = const Color(0xFF4D2069)
      ..strokeWidth = r * .06,
  );
}

/// The same mascot above the goal line. Its position follows recorded progress,
/// without a new animation timer or sensor subscription.
class StepTrailProgress extends StatelessWidget {
  const StepTrailProgress({super.key, required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    final value = progress.clamp(0.0, 1.0);
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _StepTrailMascotPainter(value)),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              borderRadius: BorderRadius.circular(8),
              semanticsLabel: 'Прогресс цели шагов',
              semanticsValue: '${(value * 100).round()}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTrailMascotPainter extends CustomPainter {
  const _StepTrailMascotPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final x = 22 + (size.width - 44).clamp(0, double.infinity) * progress;
    _drawMascot(canvas, Offset(x, 17), 13);
  }

  @override
  bool shouldRepaint(_StepTrailMascotPainter old) => old.progress != progress;
}
