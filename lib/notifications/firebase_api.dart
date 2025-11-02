import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/data/datasources/sqflite_datasource_impl.dart';
import 'package:secuchat/data/factories/db_factory_impl.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/notifications/awesome_notification_impl.dart';
import 'package:secuchat/notifications/notification_service_contract.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:secuchat/unit_components.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _miniCompositionRoot();
  await _notificationService!.createTempNotif(694930);
  final messages = await MessageService(FirebaseFirestore.instance)
      .getMessages(activeUser: _user!);
  print(messages);
  messages.forEach((message) async {
    //TODO: Impl specific functions
    var user = await _datasource!.findUser(message.from);
    var chat = await _datasource!.findChat(userId: message.from);
    String? chatId = chat?.id;
    if (user == null) {
      user = await _userService!.fetchUserId(message.from);
      if (user == null) {
        return;
      }
      await _datasource!.addUser(user);
    }
    if (chat == null) {
      chat = Chat(user.id!);
      chat.from = user;
      chatId = "${await _datasource!.addChat(chat)}";
    }

    message.contents = await _decryptMessage(message);

    final receipt = Receipt(
        messageId: message.id!,
        recipientId: user!.id!,
        status: ReceiptStatus.delivered,
        time: DateTime.now());

    LocalMessage lMessage =
        LocalMessage(message, receipt, userId: message.from, chatId: chatId!);
    int id = await _datasource!.addMessage(lMessage);
    lMessage = LocalMessage.fromJSON({...lMessage.toJSON(), "id": id});
    await _notificationService!.cancel(694930);
    await _notificationService!.createNotification(chat, lMessage);
    await _receiptService!.send(receipt);
  });
}

Future<String> _decryptMessage(Message message) async {
  final key = await _encryptionViewmodel!.getChatAcmKey(message.from);
  if (message.iv == null) {
    return message.contents;
  }
  if (key == null) {
    return message.contents;
  }
  return await _encryptionViewmodel!.encryption
      .decrypt(message.contents, message.iv!.bytes, key.secretKey);
}

Future<void> _miniCompositionRoot() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  _messageService ??= MessageService(firestore);
  _db ??= await LocalDatabaseFactory().getDatabase();
  _datasource ??= SqfliteDatasource(_db!);

  _localCache ??= LocalCache(EncryptedSharedPreferences(
      prefs: await SharedPreferences.getInstance(),
      mode: AESMode.gcm,
      randomKeyKey: 'Color#E2330'));
  _userService ??= UserService(firestore);

  _receiptService ??= ReceiptService(firestore);
  _encryptionViewmodel ??= EncryptionViewmodel(
      EncryptionService(), _datasource!, _localCache!, _userService!);
  if (_notificationService == null) {
    _notificationService = AwesomeNotificationService(
        AwesomeNotifications(),
        _messageService!,
        _datasource!,
        _encryptionViewmodel!,
        _localCache!,
        navigatorKey);
    await _notificationService!.initialize();
  }
  _user ??= User.fromJSON(_localCache!.fetch("USER"));
}

EncryptionViewmodel? _encryptionViewmodel;
IMessageService? _messageService;
IDataSource? _datasource;
ILocalCache? _localCache;
IUserService? _userService;
IReceiptService? _receiptService;
INotificationService? _notificationService;
Database? _db;
User? _user;

class FirebaseNotifications {
  final FirebaseMessaging _firebaseMessaging;

  FirebaseNotifications(this._firebaseMessaging, User? user) {
    _user = user;
  }
  Future<void> initNotifications() async {
    if (_user?.id == null) {
      return;
    }
    _firebaseMessaging.subscribeToTopic(
        _user!.id!); //? Subscribing to listen to just my email
    _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    // GetMessages().setData(fCMTokenRegisteredName, fCMToken!);
    // _messageDatabaseHelper.initializeDatabase();

    FirebaseMessaging.onMessage.listen(_onMessageRecieved);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    //   // App opened from background state via notification
    //   print('App opened from background via notification');
    //   // Handle navigation or specific actions based on the notification data
    // });
  }

  Future<void> unsubscribe(String id) async {
    _firebaseMessaging.unsubscribeFromTopic(id);
  }

  Future<void> _onMessageRecieved(RemoteMessage message) async {
    debugPrint("Hello");
  }
}
