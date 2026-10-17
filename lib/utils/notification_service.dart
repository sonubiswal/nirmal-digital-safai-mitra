// lib/utils/notification_service.dart
//
// STEP 2 — Notification Service
// ─────────────────────────────────────────────────────────────────────────────
// Wraps flutter_local_notifications.
// • initialize()              → call once in main.dart
// • showNearTruckNotification → triggered by geofence logic in HomeController
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._(); // private constructor – static use only

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Notification channel IDs ─────────────────────────────────────────────
  static const String _channelId = 'nirmal_truck_alerts';
  static const String _channelName = 'Truck Alerts';
  static const String _channelDesc =
      'Notifications when a collection truck is near you';

  // ── Unique notification IDs ───────────────────────────────────────────────
  static const int _nearTruckNotifId = 1001;
  static const int _truckArrivedNotifId = 1002;

  // ── STEP 2a: Initialize ───────────────────────────────────────────────────
  /// Call this once in main.dart before runApp().
  static Future<void> initialize() async {
    // Android init – icon must exist in android/app/src/main/res/drawable/
    // Use @mipmap/ic_launcher as a safe fallback if you have no custom icon.
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init – request permissions during init
    final iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
    );

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create the Android notification channel (required for Android 8+)
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF2E7D32), // green LED
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Request Android 13+ runtime permission
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    debugPrint('[NotificationService] Initialized');
  }

  // ── STEP 2b: Show "truck is near" notification ────────────────────────────
  /// [truckId]   – e.g. "truck_01"
  /// [etaMinutes] – estimated minutes to arrival (0 means "it's here!")
  /// [distanceM]  – distance in metres for the subtitle
  static Future<void> showNearTruckNotification({
    required String truckId,
    required int etaMinutes,
    required double distanceM,
  }) async {
    final title = etaMinutes == 0
        ? '🚛 Collection truck has arrived!'
        : '🚛 Truck approaching – $etaMinutes min away';

    final body = etaMinutes == 0
        ? 'Truck $truckId is at your location. Please bring your waste out now.'
        : 'Truck $truckId is ${distanceM.toStringAsFixed(0)} m away. '
            'Estimated arrival: $etaMinutes min.';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Truck nearby',
      color: const Color(0xFF2E7D32),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Nirmal – Waste Collection',
      ),
      // Show heads-up banner even when app is in foreground
      fullScreenIntent: etaMinutes == 0,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      etaMinutes == 0 ? _truckArrivedNotifId : _nearTruckNotifId,
      title,
      body,
      details,
      payload: truckId, // passed to _onNotificationTapped if user taps it
    );

    debugPrint('[NotificationService] Showed notification – $title');
  }

  // ── STEP 2c: Cancel all truck notifications ───────────────────────────────
  static Future<void> cancelTruckNotifications() async {
    await _plugin.cancel(_nearTruckNotifId);
    await _plugin.cancel(_truckArrivedNotifId);
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────
  static void _onNotificationTapped(NotificationResponse response) {
    // payload = truckId. You could navigate to a detail screen here.
    debugPrint(
        '[NotificationService] Notification tapped. payload=${response.payload}');
  }

  /// iOS < 10 foreground notification callback (legacy)
  static void _onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) {
    debugPrint('[NotificationService] iOS legacy notif: $title');
  }
}