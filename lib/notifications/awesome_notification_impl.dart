import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat/chat.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/material.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/composition_root.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/notifications/notification_service_contract.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

@pragma("vm:entry-point")
class AwesomeNotificationService implements INotificationService {
  static AwesomeNotificationService? _instance;
  final Map<int, List<Message>> notifMap = {};
  final IDataSource _datasource;
  final IMessageService _messageService;
  final ILocalCache _localCache;
  final EncryptionViewmodel _encryption;
  static ReceivedAction? initialAction;
  final AwesomeNotifications _awesomeNotifications;

  AwesomeNotificationService._createInstance(
      this._awesomeNotifications,
      this._messageService,
      this._datasource,
      this._encryption,
      this._localCache);

//! Singleton class
  factory AwesomeNotificationService(
      AwesomeNotifications awesomeNotifications,
      IMessageService messageService,
      IDataSource datasource,
      EncryptionViewmodel encryption,
      ILocalCache localCache) {
    _instance ??= AwesomeNotificationService._createInstance(
        awesomeNotifications,
        messageService,
        datasource,
        encryption,
        localCache);
    return _instance!;
  }
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
        importance: NotificationImportance.Low,
        defaultPrivacy: NotificationPrivacy.Public,
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
      // onNotificationDisplayedMethod: _onNotificationDisplay()
    );
  }

  @override
  Future<void> createNotification(Chat chat, LocalMessage message,
      {bool silent = false}) async {
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
        criticalAlert: !silent,
        payload: {
          'chat_id': chat.id,
          'message_id': message.id,
          'message_server_id': message.message.id,
          'user.id': chat.from.id,
          'user.photo_url': chat.from.photoUrl,
          'user.name': chat.from.name,
          //! Opposite for sending message
          'to': message.message.to,
          'from': message.message.from,
        },
        // Optional fields
        summary: "New message",
        //! Fix this should be chat_id
        groupKey: "chat_${chat.id}",
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
    if (receivedAction.buttonKeyInput.isEmpty) {
      final receiver = await _instance!._datasource!
          .findUser(receivedAction.payload!["user.id"]!);
      final me = User.fromJSON(_instance!._localCache.fetch("USER"));
      //! If user is null for any unknown reason!
      // if(user == null){
      //   _instance.
      // }
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (context) => CompositionRoot.composeMessageThreadUi(
            receiver!, me, _instance!._encryption),
      ));

      return;
    }
    print(receivedAction.payload);
    var message = Message.fromJSON({
      'id': receivedAction.payload!['message_id'],
      'time': DateTime.now(),
      'from': receivedAction.payload!['to'],
      'contents': receivedAction.buttonKeyInput.trim(),
      'to': receivedAction.payload!['from']
    });
    final chat = Chat.fromJSON({
      'id': receivedAction.payload!['chat_id'],
      'user_id': receivedAction.payload!['from']
    });
    chat.from = User(
        name: receivedAction.payload!['user.name']!,
        email: "",
        username: "",
        lastSeen: DateTime.now(),
        publicKeyJwb: '',
        active: false,
        id: receivedAction.payload!['user.id'],
        photoUrl: receivedAction.payload!['user.photo_url']);
    if (receivedAction.buttonKeyInput.isNotEmpty) {
      final uMessageC = message.contents;
      message.contents = receivedAction.buttonKeyInput;
      message = await _instance!._encryptMessage(chat.userId, message);
      message = await _instance!._messageService.send(message);
      message.contents = uMessageC;
      var lMessage = LocalMessage(
          message,
          Receipt(
              messageId: message.id!,
              recipientId: message.to,
              status: ReceiptStatus.sent,
              time: DateTime.now()),
          chatId: chat.id,
          userId: message.to);
      int id = await _instance!._datasource.addMessage(lMessage);
      lMessage = LocalMessage.fromJSON({...lMessage.toJSON(), 'id': id});
      _instance!.createNotification(chat, lMessage, silent: true);
    }

    return;
  }

  Future<Message> _encryptMessage(String userId, Message message) async {
    final key = await _encryption.getChatAcmKey(userId);
    if (key == null) {
      message.iv = null;
      return message;
    }
    message.iv = IV.fromSecureRandom(16);
    message.contents = await _encryption.encryption
        .encrypt(message.contents, message.iv!.bytes, key.secretKey);
    return message;
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
