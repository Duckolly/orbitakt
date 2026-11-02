import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _ongoingId = 1001;

  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_stat_activity');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  Future<bool> requestPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<bool> isPermissionGranted() async {
    final PermissionStatus status = await Permission.notification.status;
    return status.isGranted;
  }

  Future<void> showOngoing(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'dvizh_recording',
          'Запись активности',
          channelDescription:
              'Показывает, что приложение записывает тренировку',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          playSound: false,
          enableVibration: false,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    await _plugin.show(
      _ongoingId,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> cancelOngoing() async {
    await _plugin.cancel(_ongoingId);
  }
}
