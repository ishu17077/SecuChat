import 'dart:ffi';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/notification_service/notification_service_contract.dart';

@pragma("vm:entry-point")
class AwesomeNotificationService implements INotificationService {
  final Map<int, List<Message>> notifMap = {};
  static ReceivedAction? initialAction;
  final AwesomeNotifications _awesomeNotifications;
  AwesomeNotificationService(this._awesomeNotifications);
  @override
  Future<void> initialize() async {
    await _awesomeNotifications.initialize(null, <NotificationChannel>[
      NotificationChannel(
        channelKey: 'chat_messages',
        channelName: 'Chats',
        channelShowBadge: true,
        channelGroupKey: 'chat_messages',
        channelDescription: 'Chat Messages',
        importance: NotificationImportance.High,
        defaultPrivacy: NotificationPrivacy.Private,
        playSound: true,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        enableLights: true,
        enableVibration: true,
        ledColor: Colors.purple,
      ),
      NotificationChannel(
        channelKey: 'status_channel',
        channelName: 'Status',
        channelGroupKey: 'status_updates_group',
        channelDescription: 'Preprocess updates',
        importance: NotificationImportance.Default,
        defaultPrivacy: NotificationPrivacy.Private,
        playSound: false,
        defaultRingtoneType: DefaultRingtoneType.Notification,
        enableLights: false,
        enableVibration: false,
        ledColor: Colors.green,
      ),
    ]);
    initialAction = await _awesomeNotifications
        .getInitialNotificationAction(removeFromActionEvents: false)
        .timeout(Durations.extralong4);

    await _awesomeNotifications.setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _checkIfNotificationWithThatIdAlreadyExist,
    );
  }

  @override
  Future<void> createNotification(Chat chat, LocalMessage message) async {
    await _awesomeNotifications.createNotification(
      content: NotificationContent(
        id: int.tryParse(message.chatId!) ?? 210203,
        channelKey: 'chat_messages',
        title: chat.from.name, // Required
        body: message.message.contents, // Required
        notificationLayout: NotificationLayout.Messaging,
        category: NotificationCategory.Message,
        wakeUpScreen: true,
        fullScreenIntent: true,
        criticalAlert: true,
        // Optional fields
        summary: "New message",
        //! Fix this should be chat_id
        groupKey: "chat_${chat.from.id}",
        bigPicture: chat.from.photoUrl,
        largeIcon: chat.from.photoUrl,
      ),
      actionButtons: [
        NotificationActionButton(
          key: "REPLY",
          label: "Reply",
          requireInputText: true,
          // autoDismissible: true,
        ),
      ],
    );
  }

  @override
  Future<void> cancel(int id) async {
    await _awesomeNotifications.cancel(id);
  }

  @override
  Future<void> cancelAll() async {
    await _awesomeNotifications.cancelAll();
  }

  static Future<void> _onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyInput.isNotEmpty) {
      String textSend = receivedAction.buttonKeyInput;
      //? Impl encryption and adding to db
      debugPrint("User replied $textSend");
    }
  }

  Future<void> _checkIfNotificationWithThatIdAlreadyExist(
      ReceivedNotification receivedNotification) async {
    if (receivedNotification.id != null) {}
  }

  @override
  Future<void> createTempNotif(int id) async {
    try {
      await _awesomeNotifications.createNotification(
          content: NotificationContent(
              id: id,
              channelKey: 'status_channel',
              locked: true,
              notificationLayout: NotificationLayout.Default,
              body: 'Securing your world for you....',
              title: "SecuChat"));
    } catch (e) {
      debugPrint("Error creating temp notif: $e");
    }
  }
}
