class BreathingPreset {
  const BreathingPreset(
    this.title,
    this.inhale,
    this.exhale,
    this.minutes,
    this.hint,
  );
  final String title, hint;
  final double inhale, exhale;
  final int minutes;
  bool get paced => inhale > 0 && exhale > 0;
  static const values = [
    BreathingPreset(
      'Перед сном',
      4,
      4,
      5,
      'Дыши мягко, без усилий и задержек.',
    ),
    BreathingPreset(
      'Для утра',
      3,
      3,
      2,
      'Спокойный короткий сеанс перед началом дня.',
    ),
    BreathingPreset(
      'После занятий',
      3,
      4,
      2,
      'Начинай, когда дыхание после нагрузки уже стало спокойным.',
    ),
  ];
}

String breathingSeconds(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1).replaceAll('.', ',');

class BreathingFrame {
  BreathingFrame(BreathingPreset preset, Duration elapsed) {
    final duration = preset.minutes * 60000;
    final ms = elapsed.inMilliseconds.clamp(0, duration);
    remainingSeconds = ((duration - ms) / 1000).ceil();
    done = ms >= duration;
    progress = ms / duration;
    final inhaleMs = (preset.inhale * 1000).round();
    final exhaleMs = (preset.exhale * 1000).round();
    if (!preset.paced) {
      inhaling = true;
      phaseSeconds = 0;
      expansion = 0.5;
      return;
    }
    final position = ms % (inhaleMs + exhaleMs);
    inhaling = position < inhaleMs;
    final length = inhaling ? inhaleMs : exhaleMs;
    final phasePosition = inhaling ? position : position - inhaleMs;
    phaseSeconds = ((length - phasePosition) / 1000).ceil();
    final fraction = phasePosition / length;
    expansion = inhaling ? fraction : 1 - fraction;
  }
  late final int remainingSeconds, phaseSeconds;
  late final bool inhaling, done;
  late final double progress, expansion;
}

/// Active time uses a monotonic clock; paused/background time never accumulates.
class BreathingSession {
  BreathingSession({Duration Function()? now}) {
    final clock = Stopwatch()..start();
    _now = now ?? (() => clock.elapsed);
  }
  late final Duration Function() _now;
  Duration _accumulated = Duration.zero;
  Duration? _resumedAt;
  BreathingPreset preset = BreathingPreset.values.first;
  bool started = false, complete = false;
  bool get running => _resumedAt != null;
  Duration get elapsed =>
      _accumulated +
      (_resumedAt == null ? Duration.zero : _now() - _resumedAt!);
  BreathingFrame get frame => BreathingFrame(preset, elapsed);
  void configure(BreathingPreset value) {
    if (started) return;
    preset = value;
  }

  void start() {
    if (running || complete) return;
    started = true;
    _resumedAt = _now();
  }

  void pause() {
    if (!running) return;
    _accumulated = elapsed;
    _resumedAt = null;
    tick();
  }

  bool tick() {
    if (!started || complete || !frame.done) return false;
    _accumulated = Duration(minutes: preset.minutes);
    _resumedAt = null;
    complete = true;
    return true;
  }

  void reset() {
    _accumulated = Duration.zero;
    _resumedAt = null;
    started = false;
    complete = false;
  }
}
