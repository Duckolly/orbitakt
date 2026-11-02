class BreathingPreset {
  const BreathingPreset(
    this.title,
    this.inhale,
    this.exhale,
    this.minutes,
    this.hint,
  );
  final String title, hint;
  final int inhale, exhale, minutes;
  static const values = [
    BreathingPreset(
      'Для сна',
      4,
      6,
      3,
      'Устройся удобно. Дыши мягко, без усилий.',
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

class BreathingFrame {
  BreathingFrame(BreathingPreset preset, Duration elapsed) {
    final duration = preset.minutes * 60000;
    final ms = elapsed.inMilliseconds.clamp(0, duration);
    remainingSeconds = ((duration - ms) / 1000).ceil();
    done = ms >= duration;
    final cycle = (preset.inhale + preset.exhale) * 1000;
    final position = ms % cycle;
    inhaling = position < preset.inhale * 1000;
    final phaseLength = (inhaling ? preset.inhale : preset.exhale) * 1000;
    final phasePosition = inhaling ? position : position - preset.inhale * 1000;
    phaseSeconds = ((phaseLength - phasePosition) / 1000).ceil();
    progress = ms / duration;
  }
  late final int remainingSeconds, phaseSeconds;
  late final bool inhaling, done;
  late final double progress;
}
