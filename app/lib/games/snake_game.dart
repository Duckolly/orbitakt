import 'dart:math';

enum SnakeDirection { up, right, down, left }

enum SnakePhase { ready, running, paused, lost, won }

/// Original grid game implementation, independent of rendering and device sensors.
class SnakeGame {
  SnakeGame({this.columns = 16, this.rows = 16, Random? random})
    : _random = random ?? Random() {
    if (columns < 4 || rows < 4) throw ArgumentError('Board is too small');
    reset();
  }
  final int columns;
  final int rows;
  final Random _random;
  late List<Point<int>> _body;
  List<Point<int>> get body => List.unmodifiable(_body);
  Point<int>? food;
  SnakeDirection direction = SnakeDirection.right;
  SnakeDirection? _pending;
  SnakePhase phase = SnakePhase.ready;
  int score = 0;

  void reset() {
    final x = columns ~/ 2, y = rows ~/ 2;
    _body = [Point(x, y), Point(x - 1, y), Point(x - 2, y)];
    direction = SnakeDirection.right;
    _pending = null;
    score = 0;
    phase = SnakePhase.ready;
    _spawnFood();
  }

  void start() {
    if (phase == SnakePhase.ready || phase == SnakePhase.paused) {
      phase = SnakePhase.running;
    }
  }

  void pause() {
    if (phase == SnakePhase.running) phase = SnakePhase.paused;
  }

  bool turn(SnakeDirection next) {
    if (phase != SnakePhase.running ||
        _pending != null ||
        next == direction ||
        (next.index - direction.index).abs() == 2) {
      return false;
    }
    _pending = next;
    return true;
  }

  void tick() {
    if (phase != SnakePhase.running) return;
    direction = _pending ?? direction;
    _pending = null;
    final head = _body.first;
    final Point<int> next = switch (direction) {
      SnakeDirection.up => Point(head.x, head.y - 1),
      SnakeDirection.right => Point(head.x + 1, head.y),
      SnakeDirection.down => Point(head.x, head.y + 1),
      SnakeDirection.left => Point(head.x - 1, head.y),
    };
    final grows = next == food;
    final occupied = grows ? _body : _body.take(_body.length - 1);
    if (next.x < 0 ||
        next.y < 0 ||
        next.x >= columns ||
        next.y >= rows ||
        occupied.contains(next)) {
      phase = SnakePhase.lost;
      return;
    }
    _body.insert(0, next);
    if (grows) {
      score++;
      _spawnFood();
    } else {
      _body.removeLast();
    }
  }

  void _spawnFood() {
    final free = <Point<int>>[];
    final occupied = _body.toSet();
    for (var y = 0; y < rows; y++) {
      for (var x = 0; x < columns; x++) {
        final cell = Point(x, y);
        if (!occupied.contains(cell)) free.add(cell);
      }
    }
    if (free.isEmpty) {
      food = null;
      phase = SnakePhase.won;
    } else {
      food = free[_random.nextInt(free.length)];
    }
  }
}
