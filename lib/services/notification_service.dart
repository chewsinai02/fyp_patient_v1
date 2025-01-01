import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isInitialized => _initialized;

  NotificationService._();

  Future<void> requestPermissions() async {
    try {
      print('\n=== REQUESTING NOTIFICATION PERMISSIONS ===');
      if (Platform.isAndroid) {
        // Get the Android implementation
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _notifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        // Create notification channel first
        const channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        );

        await androidImplementation?.createNotificationChannel(channel);

        // Force permission request regardless of current status
        print('Requesting notification permissions...');
        if (await androidImplementation?.requestNotificationsPermission() ??
            false) {
          print('Notification permissions granted');
        } else {
          print('Notification permissions denied');
          // Try requesting again through system settings
          await androidImplementation?.requestNotificationsPermission();
        }
      }
      print('=== PERMISSION REQUEST COMPLETE ===\n');
    } catch (e) {
      print('Error requesting permissions: $e');
      print(e.toString());
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Create task notification channel
    if (Platform.isAndroid) {
      final androidImplementation =
          _notifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(
        const AndroidNotificationChannel(
          'task_reminders',
          'Task Reminders',
          description: 'Notifications for upcoming tasks',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          showBadge: true,
        ),
      );
    }

    await _notifications.initialize(initSettings);
    _initialized = true;
  }

  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      print('\n=== SHOWING NOTIFICATION ===');
      print('Title: $title');
      print('Body: $body');
      print('Payload: $payload');

      if (!_initialized) {
        print('Service not initialized, initializing now...');
        await initialize();
      }

      final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('Generated notification ID: $id');

      print('Creating notification details...');
      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'New Message',
        icon: '@mipmap/ic_launcher',
        enableLights: true,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.message,
      );

      final platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        ),
      );

      print('Showing notification...');
      await _notifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      print('Notification shown successfully');
      print('=== NOTIFICATION COMPLETE ===\n');
    } catch (e, stackTrace) {
      print('\n=== NOTIFICATION ERROR ===');
      print('Error showing notification:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('========================\n');
    }
  }
}
