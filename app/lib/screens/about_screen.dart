import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});
  static const websiteUrl = 'https://duckolly.github.io/testofsilence/';
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

  Future<void> _openLink(String method) async {
    if (opening) return;
    setState(() => opening = true);
    try {
      final opened =
          await AboutScreen.channel.invokeMethod<bool>(method) ?? false;
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

  Future<void> _copyLink(String address, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: address));
      _message(message);
    } catch (_) {
      _message('Не удалось скопировать адрес. Он показан на экране.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight:
          56 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0),
      title: const Text(
        'О приложении и авторе',
        maxLines: 2,
        style: TextStyle(fontSize: 18),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Орбитакт', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Версия: $version'),
          const SizedBox(height: 8),
          const Text(
            '16+ · Для пользователей от 16 лет',
            key: Key('aboutMinimumAge'),
          ),
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
                  Text('Сайт с рассказом', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const SelectableText(AboutScreen.websiteUrl),
                  const SizedBox(height: 8),
                  const Text(
                    'Ссылка откроется в браузере. Нужен интернет; история приложения к ссылке не прикрепляется.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    key: const Key('openWebsite'),
                    onPressed: opening ? null : () => _openLink('openWebsite'),
                    icon: const Icon(Icons.language),
                    label: const Text('Открыть сайт'),
                  ),
                  TextButton.icon(
                    key: const Key('copyWebsite'),
                    onPressed: () => _copyLink(
                      AboutScreen.websiteUrl,
                      'Адрес сайта скопирован',
                    ),
                    icon: const Icon(Icons.copy),
                    label: const Text('Скопировать ссылку на сайт'),
                  ),
                ],
              ),
            ),
          ),
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
                    'Новости и обратная связь — в группе. Для перехода нужен интернет. Ссылка откроется во внешнем приложении; данные Орбитакта к ней не прикрепляются.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: opening ? null : () => _openLink('openTelegram'),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Открыть Telegram'),
                  ),
                  TextButton.icon(
                    onPressed: () => _copyLink(
                      AboutScreen.telegramUrl,
                      'Адрес Telegram скопирован',
                    ),
                    icon: const Icon(Icons.copy),
                    label: const Text('Скопировать адрес'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Для сообщения об ошибке укажи модель телефона, версию Android, версию Орбитакта и шаги воспроизведения. Личные данные отправлять не нужно.',
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
