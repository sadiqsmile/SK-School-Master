// services/notification_service.dart
import 'package:flutter/foundation.dart';

class NotificationService {
  const NotificationService();

  void showInfo(String message) {
    if (kDebugMode) {
      debugPrint('INFO: $message');
    }
  }
}
