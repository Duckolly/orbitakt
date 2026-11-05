import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/seasonal_controller.dart';

/// Home-only skin: pushed tools retain the original application theme.
class SeasonalSurface extends StatelessWidget {
  const SeasonalSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<SeasonalAppearance>(
        valueListenable: SeasonalController.appearance,
        child: child,
        builder: (context, value, child) {
          if (!value.newYear) return child!;
          final theme = Theme.of(context);
          final dark = theme.brightness == Brightness.dark;
          final accent = dark
              ? const Color(0xFF98E4CE)
              : const Color(0xFF146C58);
          final gold = dark ? const Color(0xFFE5CB8A) : const Color(0xFF896623);
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: accent,
                secondary: gold,
              ),
              cardTheme: theme.cardTheme.copyWith(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(color: gold.withValues(alpha: .7)),
                ),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? const [Color(0xFF122A2C), Color(0xFF222535)]
                      : const [Color(0xFFEAF8F2), Color(0xFFFFF5DC)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: child!),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: RepaintBoundary(
                          child: _SeasonalSnow(
                            animate: value.animate,
                            color: dark ? const Color(0xFFDDF7EE) : accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _SeasonalSnow extends StatefulWidget {
  const _SeasonalSnow({required this.animate, required this.color});
  final bool animate;
  final Color color;
  @override
  State<_SeasonalSnow> createState() => _SeasonalSnowState();
}

class _SeasonalSnowState extends State<_SeasonalSnow>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _foreground = true;
  bool _reduced = false;
  bool _tickers = true;
  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  void _sync() {
    final run = widget.animate && _foreground && !_reduced && _tickers;
    if (run && !_motion.isAnimating) _motion.repeat();
    if (!run && _motion.isAnimating) _motion.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced =
        MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    _tickers = TickerMode.of(context);
    _sync();
  }

  @override
  void didUpdateWidget(_SeasonalSnow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SnowPainter(_motion, widget.color));
}

class _SnowPainter extends CustomPainter {
  _SnowPainter(this.motion, this.color) : super(repaint: motion);
  final Animation<double> motion;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .28)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    // Sparse edge decorations leave text and the existing cat unobscured.
    for (var i = 0; i < 16; i++) {
      final x = i.isEven ? 7.0 : size.width - 7;
      final y = ((i / 16 + motion.value) % 1) * size.height;
      final r = i % 3 + 2.0;
      for (var arm = 0; arm < 3; arm++) {
        final a = arm * math.pi / 3;
        canvas.drawLine(
          Offset(x - math.cos(a) * r, y - math.sin(a) * r),
          Offset(x + math.cos(a) * r, y + math.sin(a) * r),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_SnowPainter oldDelegate) =>
      color != oldDelegate.color || motion != oldDelegate.motion;
}
