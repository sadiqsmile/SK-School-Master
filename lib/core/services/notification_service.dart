import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';


class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {

    // Disable notification permission popup on WEB
    if (kIsWeb) return;

    await _messaging.requestPermission();

    final token = await _messaging.getToken();

    print("FCM TOKEN: $token");

    FirebaseMessaging.onMessage.listen((message) {
      print(
        "Foreground Notification: ${message.notification?.title}",
      );
    });
  }
}