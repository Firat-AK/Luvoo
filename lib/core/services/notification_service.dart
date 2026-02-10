import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles FCM push notifications: init, permissions, token, message handling.
class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _firestore = FirebaseFirestore.instance;
  final _tapController = StreamController<RemoteMessage>.broadcast();

  /// Stream of notification taps - use for navigation.
  Stream<RemoteMessage> get onNotificationTap => _tapController.stream;

  /// Initialize notifications: request permission, get token, setup handlers.
  Future<void> initialize() async {
    // Request permission (iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('[Notifications] Permission: ${settings.authorizationStatus}');

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[Notifications] FCM token: ${token.substring(0, 20)}...');
    }

    // Foreground: show in-app when message received
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background/terminated: when user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // App launched from terminated state via notification tap
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[Notifications] Token refreshed');
    });
  }

  /// Save FCM token to Firestore for the given user. Call after login.
  Future<void> saveTokenForUser(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('[Notifications] Token saved for user $userId');
      }
    } catch (e) {
      debugPrint('[Notifications] Failed to save token: $e');
    }
  }

  /// Remove FCM token when user logs out.
  Future<void> removeTokenForUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('[Notifications] Failed to remove token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[Notifications] Foreground: ${message.notification?.title}');
    // Optionally show in-app banner when app is open
  }

  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[Notifications] Tap: ${message.data}');
    _tapController.add(message);
  }

  void dispose() => _tapController.close();

  /// Delete token (call on logout).
  Future<void> deleteToken() async {
    await _messaging.deleteToken();
  }
}
