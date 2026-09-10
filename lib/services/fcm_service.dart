import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'push_service.dart';

class FcmService {
  static bool _listening = false;

  static Future<String?> setup() async {
    if (kIsWeb) return null;
    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } on Exception {
      return null;
    }

    if (!_listening) {
      _listening = true;
      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        PushService.showNow(
          key: message.messageId ?? DateTime.now().toIso8601String(),
          title: notification.title ?? 'Smart Mentor',
          body: notification.body ?? '',
        );
      });
    }

    try {
      return await messaging.getToken();
    } on Exception {
      return null;
    }
  }
}
