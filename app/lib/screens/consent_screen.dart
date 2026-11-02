import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _privacyAccepted = false;
  bool _ageConfirmed = false;
  bool _offlineUnderstood = false;

  bool get _canContinue =>
      _privacyAccepted && _ageConfirmed && _offlineUnderstood;

  // R-3: офлайн-текст policy, читаемый ВНУТРИ приложения (без WebView =>
  // без сетевого запроса, офлайн-дух не нарушается). Ссылка — текст для
  // пользователя, а не запрос.
  static const String _policyShort =
      'Движ работает офлайн и не имеет сервера. '
      'Приложение не собирает ФИО, email, телефон, адрес, геолокацию, вес и '
      'диагнозы, не использует рекламу, аналитику и crash reporting, '
      'не отправляет данные разработчику или третьим лицам. '
      'История тренировок, дневные итоги шагов и воды, настройки хранятся только на этом устройстве. '
      'Дневной шагомер включается отдельно и работает в фоновой службе с системным уведомлением. '
      'Выключение режима прекращает новый учёт шагов; после перезагрузки требуется возобновление. '
      'Вода отмечается вручную по 200 мл. Добавленный вами виджет показывает шаги и воду на рабочем столе. '
      'Бегалка сохраняет только локальный рекорд; экран датчиков показывает доступное оборудование без отправки сведений. '
      'Вы можете очистить историю или удалить все данные внутри приложения. '
      'Приложение не является медицинским изделием. '
      'Полный текст также включён в PRIVACY.md комплекта приложения.';

  void _showPolicy() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.5,
        builder: (BuildContext _, ScrollController c) => SingleChildScrollView(
          controller: c,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Политика конфиденциальности',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SelectableText(_policyShort),
              const SizedBox(height: 16),
              const Text(
                'Полная версия доступна по ссылке выше и в файле PRIVACY.md '
                'репозитория.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _continue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('privacyAccepted', true);
    await prefs.setBool('ageConfirmed', true);
    await prefs.setBool('offlineUnderstood', true);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const HomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Движ')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Приватность прежде всего',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              const Text(
                'Это офлайн-приложение для локального учёта активности.\n\n'
                'Оно:\n'
                '• не требует регистрации;\n'
                '• не отправляет данные на сервер;\n'
                '• не использует рекламу;\n'
                '• не использует аналитику;\n'
                '• хранит историю только на этом устройстве.',
                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 16),

              // R-3: доступ к тексту ДО чекбокса «ознакомился».
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _showPolicy,
                  icon: const Icon(Icons.privacy_tip_outlined),
                  label: const Text('Читать политику конфиденциальности'),
                ),
              ),

              const SizedBox(height: 8),

              CheckboxListTile(
                value: _privacyAccepted,
                onChanged: (bool? value) {
                  setState(() {
                    _privacyAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'Я ознакомился с политикой конфиденциальности',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                value: _ageConfirmed,
                onChanged: (bool? value) {
                  setState(() {
                    _ageConfirmed = value ?? false;
                  });
                },
                title: const Text(
                  'Мне исполнилось 14 лет, либо я использую приложение '
                  'с согласия законного представителя',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                value: _offlineUnderstood,
                onChanged: (bool? value) {
                  setState(() {
                    _offlineUnderstood = value ?? false;
                  });
                },
                title: const Text(
                  'Я понимаю, что данные не передаются автоматически '
                  'и хранятся только на устройстве',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),

              const SizedBox(height: 24),

              FilledButton(
                onPressed: _canContinue ? _continue : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Продолжить'),
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () {
                  SystemNavigator.pop();
                },
                child: const Text('Не согласен'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
