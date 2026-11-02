Да, это абсолютно реально! Смартфон можно превратить в шагомер без всяких часов и трекеров. Давайте разберём, как это работает и какие у вас есть варианты.

## Как это работает технически

В любом смартфоне есть **акселерометр** — датчик, который измеряет ускорение по трём осям (X, Y, Z). Когда вы идёте, телефон в кармане или руке совершает характерные колебания. Приложение считывает эти данные и с помощью алгоритма определяет, что именно это был шаг, а не просто тряска.

**Базовый алгоритм:**
1. Чтение данных с акселерометра (обычно 50–100 раз в секунду).
2. Фильтрация шума (low-pass filter) — убираем дрожание рук, вибрации.
3. Подсчёт пиков ускорения выше определённого порога (обычно ~1.2g).
4. Если между двумя пиками прошло 0.3–0.7 секунды — это шаг.
5. Всё работает локально, офлайн, без интернета.

---

## Вариант 1: Использовать готовое приложение (проще всего)

Если вам нужно просто считать шаги, а не разрабатывать своё — вот проверенные бесплатные офлайн-шагомеры:

| Приложение | Платформа | Особенности |
|-----------|-----------|-------------|
| **Pedometer Step Counter** (Leap Fitness) | Android | Полностью офлайн, без GPS, минимальный расход батареи |
| **StepSetGo** | Android/iOS | Простой интерфейс, работает в фоне |
| **Google Fit** | Android/iOS | Использует встроенный датчик шагов (если есть) или акселерометр |
| **Apple Здоровье** | iOS | Встроено в iPhone, использует сопроцессор движения (почти не жрёт батарею) |
| **Samsung Health** | Android (Samsung) | Аналогично Apple Health |

**Важно:** На iPhone с чипом M-серии (начиная с iPhone 5s) есть отдельный **сопроцессор движения** — он считает шаги даже когда телефон выключен. На Android это зависит от модели.

---

## Вариант 2: Написать своё приложение

Если вам интересна разработка или нужно специфическое решение (например, с кастомной аналитикой), вот минимальный рабочий пример на **Flutter** (кроссплатформа: Android + iOS).

### Шаг 1: Создайте проект
```bash
flutter create step_counter
cd step_counter
```

### Шаг 2: Добавьте зависимости в `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  sensors_plus: ^4.0.2
  permission_handler: ^11.0.0
```

### Шаг 3: Основной код (`lib/main.dart`)
```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const StepCounterApp());

class StepCounterApp extends StatelessWidget {
  const StepCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: StepCounterPage());
  }
}

class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});
  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  int _steps = 0;
  double _lastMagnitude = 0;
  DateTime _lastStepTime = DateTime.now();
  
  // Порог ускорения для определения шага (в g)
  static const double _stepThreshold = 1.3;
  // Минимальный интервал между шагами (мс)
  static const int _minStepIntervalMs = 300;

  @override
  void initState() {
    super.initState();
    _listenToAccelerometer();
  }

  void _listenToAccelerometer() {
    accelerometerEventStream().listen((event) {
      // Вычисляем общую величину ускорения
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final now = DateTime.now();
      final timeSinceLastStep = now.difference(_lastStepTime).inMilliseconds;

      // Детекция шага: пик выше порога + достаточный интервал
      if (magnitude > _stepThreshold &&
          _lastMagnitude <= _stepThreshold &&
          timeSinceLastStep > _minStepIntervalMs) {
        setState(() {
          _steps++;
          _lastStepTime = now;
        });
      }

      _lastMagnitude = magnitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Шагомер офлайн')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_walk, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              '$_steps',
              style: const TextStyle(fontSize: 72, fontWeight: FontWeight.bold),
            ),
            const Text('шагов', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => setState(() => _steps = 0),
              child: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Шаг 4: Запуск
```bash
flutter run
```

---

## Ограничения и нюансы

1. **Точность:** Простой алгоритм на акселерометре даёт погрешность ±10–20%. Для медицинских целей не подходит, для общей активности — достаточно.
2. **Расход батареи:** Чтение датчика 50 раз в секунду съедает ~5–10% батареи в час. Решение — использовать `SensorManager.SENSOR_DELAY_NORMAL` или пакетную обработку.
3. **Фоновый режим:** Чтобы считать шаги когда телефон в кармане, нужно настроить **foreground service** (Android) или **background fetch** (iOS). Без этого ОС убьёт приложение через несколько минут.
4. **Размещение телефона:** Точность зависит от того, где лежит телефон (карман брюк — лучше всего, сумка — хуже, рука — средне).

---

## Что я рекомендую

- **Если нужно просто считать шаги** → поставьте **Pedometer Step Counter** (Android) или используйте **Apple Здоровье** (iOS). Это займёт 2 минуты.
- **Если хотите своё приложение для работы/учёбы** → используйте код выше как стартовую точку. Для продакшена нужно добавить: фильтрацию Калмана, сохранение истории в SQLite, фоновый режим.
- **Если нужна высокая точность** → используйте `pedometer` API (есть на Android через `Sensor.TYPE_STEP_COUNTER`) — он аппаратный и даёт точность как у фитнес-браслетов.

Если хотите, могу:
- Написать версию на **чистом Kotlin для Android** с использованием аппаратного шагомера (максимальная точность).
- Добавить **сохранение истории** шагов по дням в локальную базу.
- Сделать **фоновый режим** с уведомлением в статус-баре.

Что из этого вам интереснее?