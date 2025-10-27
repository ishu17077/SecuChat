import 'dart:typed_data';
import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class LocalNotificationService {
  LocalNotificationService();

  final _localNotificationService = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: initializationSettingsDarwin);

    await _localNotificationService.initialize(
      settings,
      onDidReceiveNotificationResponse: onRecieveNotificationResponse,
    );
  }

  void onRecieveNotificationResponse(NotificationResponse details) {
    //TODO Impl
    navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => ChatPage()),
        (Route<dynamic> route) => false);
  }

  Future<void> showNotificationMessage(
      {int id = 0,
      required String title,
      required String body,
      Uint8List? imageBytes,
      var payload}) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'messages_from_people',
      'Messages',
      playSound: true,
      largeIcon: imageBytes != null ? ByteArrayAndroidBitmap(imageBytes) : null,
      // sound: RawResourceAndroidNotificationSound('notification'),
      importance: Importance.max,

      priority: Priority.max,
      styleInformation: BigTextStyleInformation(''),
    );
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    _localNotificationService.show(id, title, body, notificationDetails,
        payload: payload);
  }

  Future<void> showNotificationChecker(
      {int id = 9999999,
      required String title,
      required String body,
      var payload}) async {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'checking_messages',
      'Checking New Messages',
      playSound: false,
      autoCancel: true,
      // sound: RawResourceAndroidNotificationSound('notification'),
      importance: Importance.low,
      priority: Priority.low,
    );
    NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    _localNotificationService.show(id, title, body, notificationDetails);
  }

  Future<void> dismissNotification(int id) async {
    _localNotificationService.cancel(id);
  }
}
