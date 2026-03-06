import 'package:flutter/foundation.dart';

class NotificationService {
  const NotificationService();

  void showInfo(String message) {
    debugPrint('INFO: $message');
  }
}
