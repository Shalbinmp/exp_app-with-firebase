import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

class LocalNotification {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const  InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

     await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        final payload = details.payload;
        print('jdshfjs');
        if (payload != null && payload.isNotEmpty) {
          print('not printing');
          await _handleNotificationClick(payload);
        }
      },
    );
  }

  static Future<void> _handleNotificationClick(String payload) async {
    print('Payload received: $payload');
    OpenFile.open(payload);
  }

  static Future showNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    print(payload);
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'id',
      'name',
      channelDescription: 'Payslip Document',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      playSound: true,
      // sound:
      color:Color(255),
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    print("ddddddddddddddddddddddddd");
  }
}
