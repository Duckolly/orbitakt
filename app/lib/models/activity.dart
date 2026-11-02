import 'package:flutter/material.dart';

enum ActivityType {
  walking('Ходьба', Icons.directions_walk),
  running('Бег', Icons.directions_run),
  workout('Зарядка', Icons.fitness_center);

  final String title;
  final IconData icon;

  const ActivityType(this.title, this.icon);
}
