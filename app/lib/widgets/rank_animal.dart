import 'package:flutter/material.dart';
import '../models/rank_level.dart';

class RankAnimal extends StatelessWidget {
  const RankAnimal(this.rank, {super.key, this.size = 48});
  final RankLevel? rank;
  final double size;
  static const assets = <String, String>{
    'Лиса': 'steps_fox',
    'Волк': 'steps_wolf',
    'Лев': 'steps_lion',
    'Пантера': 'steps_panther',
    'Дракон': 'steps_dragon',
    'Выдра': 'water_otter',
    'Дельфин': 'water_dolphin',
    'Акула': 'water_shark',
    'Косатка': 'water_orca',
    'Синий кит': 'water_whale',
    'Заяц': 'toilet_hare',
    'Обезьяна': 'toilet_monkey',
    'Эму': 'toilet_emu',
    'Динозавр': 'toilet_dinosaur',
  };
  @override
  Widget build(BuildContext context) {
    final asset = assets[rank?.animal];
    return Semantics(
      label: rank?.animal ?? 'Без животного',
      image: asset != null,
      child: SizedBox.square(
        dimension: size,
        child: asset == null
            ? Icon(
                Icons.spa_outlined,
                size: size * .65,
                color: Theme.of(context).colorScheme.primary,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(size * .18),
                child: Image.asset(
                  'assets/ranks/$asset.webp',
                  fit: BoxFit.contain,
                  cacheWidth: (size * 3).round(),
                  excludeFromSemantics: true,
                ),
              ),
      ),
    );
  }
}
