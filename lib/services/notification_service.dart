import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const _channel = AndroidNotificationChannel(
    'splitka_updates',
    'Nowe rachunki i zakupy',
    description: 'Powiadomienia o zmianach we wspólnych grupach Splitki.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _roomId;
  String? _memberId;
  bool _initialized = false;

  Future<bool> enable(String roomId, String memberId) async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return false;
    }

    await _initializeLocalNotifications();
    _roomId = roomId;
    _memberId = memberId;
    final token = await messaging.getToken();
    if (token == null) return false;
    await _register(token);

    await _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen(_register);
    return true;
  }

  Future<void> restore(String roomId, String memberId) async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.denied ||
        settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      return;
    }
    await enable(roomId, memberId);
  }

  Future<void> disable(String roomId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance
          .collection('households')
          .doc(roomId)
          .collection('notificationDevices')
          .doc(uid)
          .delete();
    }
    if (_roomId == roomId) {
      _roomId = null;
      _memberId = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
    }
  }

  Future<void> _register(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final roomId = _roomId;
    final memberId = _memberId;
    if (uid == null || roomId == null || memberId == null) return;
    await FirebaseFirestore.instance
        .collection('households')
        .doc(roomId)
        .collection('notificationDevices')
        .doc(uid)
        .set({
          'uid': uid,
          'token': token,
          'memberId': memberId,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _initializeLocalNotifications() async {
    if (_initialized) return;
    const initialization = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(settings: initialization);
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      unawaited(
        _local.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(),
          ),
        ),
      );
    });
    _initialized = true;
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _foregroundSubscription?.cancel();
  }
}
