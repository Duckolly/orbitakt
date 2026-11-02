import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  static const telegramUrl = 'https://t.me/dvizhoffline';
  static const channel = MethodChannel('dvizh/about');
  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String version = 'Загрузка…';
  bool opening = false;
  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    var label = 'Недоступна';
    try {
      final info = await AboutScreen.channel.invokeMapMethod<String, dynamic>(
        'info',
      );
      final name = info?['version'];
      final build = info?['build'];
      if (name is String && name.isNotEmpty && build is int && build > 0) {
        label = '$name (сборка $build)';
      }
    } catch (_) {
      /* Keep the contact usable even without package metadata. */
    }
    if (mounted) setState(() => version = label);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _openTelegram() async {
    if (opening) return;
    setState(() => opening = true);
    try {
      final opened =
          await AboutScreen.channel.invokeMethod<bool>('openTelegram') ?? false;
      if (!opened) {
        _message(
          'Не удалось открыть ссылку. Скопируйте адрес и откройте его вручную.',
        );
      }
    } catch (_) {
      _message(
        'Не удалось открыть ссылку. Скопируйте адрес и откройте его вручную.',
      );
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<void> _copyContact() async {
    try {
      await Clipboard.setData(
        const ClipboardData(text: AboutScreen.telegramUrl),
      );
      _message('Адрес Telegram скопирован');
    } catch (_) {
      _message('Не удалось скопировать адрес. Он показан на экране.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('О приложении и связь')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Движ', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Версия: $version'),
          const SizedBox(height: 16),
          const Text(
            'Шаги, вода и отдых без интернета. Данные хранятся на устройстве и не отправляются автоматически.',
          ),
          const SizedBox(height: 20),
          const Text('Автор: Сергей Швецов'),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Сообщество в Telegram',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const SelectableText('@dvizhoffline'),
                  const SizedBox(height: 4),
                  const SelectableText(AboutScreen.telegramUrl),
                  const SizedBox(height: 12),
                  const Text(
                    'Новости и обратная связь — в группе. Для перехода нужен интернет. Ссылка откроется во внешнем приложении; данные Движа к ней не прикрепляются.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: opening ? null : _openTelegram,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Открыть Telegram'),
                  ),
                  TextButton.icon(
                    onPressed: _copyContact,
                    icon: const Icon(Icons.copy),
                    label: const Text('Скопировать адрес'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Для сообщения об ошибке укажи модель телефона, версию Android, версию Движа и шаги воспроизведения. Личные данные отправлять не нужно.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Приложение не является медицинским изделием. Доступность и точность датчиков зависят от телефона.',
          ),
        ],
      ),
    ),
  );
}
