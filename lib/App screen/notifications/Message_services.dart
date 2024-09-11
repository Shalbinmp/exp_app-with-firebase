import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageServices {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  FirebaseMessaging _fcm = FirebaseMessaging.instance;

  void requestNotificationPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: true,
      criticalAlert: true,
      provisional: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission granted');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Provisional permission granted');
    } else {
      print('Permission denied');
    }
  }

  Future initialize(Function(RemoteMessage) onMessageReceived) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _saveNotificationDetails(message.notification!.title, message.notification!.body);
        onMessageReceived(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      if (message.notification != null) {
        _saveNotificationDetails(message.notification!.title, message.notification!.body);
      }
      // Notify the HomeScreen to update the UI
      onMessageReceived(message);
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await getToken();
  }

  Future<String?> getToken() async {
    String? token = await _fcm.getToken();
    print('Token: $token');
    return token;
  }

  Future<void> _saveNotificationDetails(String? title, String? body) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('notificationTitle', title ?? "No Title");
    await prefs.setString('notificationBody', body ?? "No Body");
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('notificationTitle', message.notification?.title ?? "No Title");
  await prefs.setString('notificationBody', message.notification?.body ?? "No Body");
}
