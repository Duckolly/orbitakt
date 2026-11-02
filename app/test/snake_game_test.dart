import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dvizh/games/snake_game.dart';

void main() {
  test('start and pause control ticks without changing the saved board', () {
    final game = SnakeGame(random: Random(1));
    final head = game.body.first;
    game.tick();
    expect(game.body.first, head);
    game.start();
    game.food = const Point(0, 0);
    game.tick();
    expect(game.body.first.x, head.x + 1);
    game.pause();
    final paused = game.body;
    game.tick();
    expect(game.body, paused);
    game.start();
    game.tick();
    expect(game.body.first.x, head.x + 2);
  });
  test('opposite direction and multiple turns in one tick are rejected', () {
    final game = SnakeGame()..start();
    expect(game.turn(SnakeDirection.left), false);
    expect(game.turn(SnakeDirection.down), true);
    expect(game.turn(SnakeDirection.left), false);
    game.tick();
    expect(game.direction, SnakeDirection.down);
    expect(game.turn(SnakeDirection.left), true);
  });
  test('food grows body once and never respawns inside it', () {
    final game = SnakeGame(random: Random(2))..start();
    final head = game.body.first;
    game.food = Point(head.x + 1, head.y);
    game.tick();
    expect(game.score, 1);
    expect(game.body.length, 4);
    expect(game.body.contains(game.food), false);
  });
  test('wall collision ends the game without moving outside the board', () {
    final game = SnakeGame()..start();
    game.food = const Point(0, 0);
    for (var i = 0; i < 30; i++) {
      game.tick();
    }
    expect(game.phase, SnakePhase.lost);
    expect(game.body.first.x, game.columns - 1);
  });
  test('moving into the departing tail is allowed', () {
    final game = SnakeGame()..start();
    final h = game.body.first;
    game.food = Point(h.x + 1, h.y);
    game.tick();
    game.food = const Point(0, 0);
    game.turn(SnakeDirection.down);
    game.tick();
    game.turn(SnakeDirection.left);
    game.tick();
    final tail = game.body.last;
    game.turn(SnakeDirection.up);
    game.tick();
    expect(game.phase, SnakePhase.running);
    expect(game.body.first, tail);
  });
  test('body collision ends the game', () {
    final game = SnakeGame()..start();
    final h = game.body.first;
    game.food = Point(h.x + 1, h.y);
    game.tick();
    game.turn(SnakeDirection.down);
    game.food = Point(h.x + 1, h.y + 1);
    game.tick();
    game.turn(SnakeDirection.left);
    game.food = Point(h.x, h.y + 1);
    game.tick();
    game.turn(SnakeDirection.up);
    game.food = const Point(0, 0);
    game.tick();
    expect(game.phase, SnakePhase.lost);
  });
  test('filling the board wins without searching forever for food', () {
    final game = SnakeGame(columns: 4, rows: 4, random: Random(4))..start();
    const path = [
      Point(2, 1),
      Point(1, 1),
      Point(0, 1),
      Point(0, 0),
      Point(1, 0),
      Point(2, 0),
      Point(3, 0),
      Point(3, 1),
      Point(3, 2),
      Point(3, 3),
      Point(2, 3),
      Point(1, 3),
      Point(0, 3),
    ];
    for (final p in path) {
      final h = game.body.first;
      game.turn(
        p.x > h.x
            ? SnakeDirection.right
            : p.x < h.x
            ? SnakeDirection.left
            : p.y > h.y
            ? SnakeDirection.down
            : SnakeDirection.up,
      );
      game.food = p;
      game.tick();
    }
    expect(game.phase, SnakePhase.won);
    expect(game.body.length, 16);
    expect(game.food, isNull);
    game.reset();
    expect(game.phase, SnakePhase.ready);
    expect(game.score, 0);
    expect(game.body.length, 3);
  });
}
