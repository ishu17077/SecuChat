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
import 'package:secuchat/notification_service/awesome_notification_impl.dart';
import 'package:secuchat/notification_service/notification_service_contract.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _miniCompositionRoot();
  await notificationService!.createTempNotif(999999999999);
  final messages = await MessageService(FirebaseFirestore.instance)
      .getMessages(activeUser: user!);
  print(messages);
  messages.forEach((message) async {
    //TODO: Impl specific functions
    var user = await dataSource!.findUser(message.from);
    var chat = await dataSource!.findChat(userId: message.from);
    String? chatId = chat?.id;
    if (user == null) {
      user = await userService!.fetchUserId(message.from);
      if (user == null) {
        return;
      }
      await dataSource!.addUser(user);
    }
    if (chat == null) {
      chat = Chat(user.id!);
      chat.from = user;
      chatId = "${await dataSource!.addChat(chat)}";
    }

    message.contents = await _decryptMessage(message);

    final receipt = Receipt(
        messageId: message.id!,
        recipientId: user!.id!,
        status: ReceiptStatus.delivered,
        time: DateTime.now());

    LocalMessage lMessage =
        LocalMessage(message, receipt, userId: message.from, chatId: chatId!);
    await dataSource!.addMessage(lMessage);
    await notificationService!.cancel(999999999999);
    await notificationService!.createNotification(chat, lMessage);
    await receiptService!.send(receipt);
  });
}

Future<String> _decryptMessage(Message message) async {
  final key = await encryptionViewmodel!.getChatAcmKey(message.from);
  if (message.iv == null) {
    return message.contents;
  }
  if (key == null) {
    return message.contents;
  }
  return await encryptionViewmodel!.encryption
      .decrypt(message.contents, message.iv!.bytes, key.secretKey);
}

Future<void> _miniCompositionRoot() async {
  await Firebase.initializeApp();
  final firestore = FirebaseFirestore.instance;
  messageService ??= MessageService(firestore);
  _db ??= await LocalDatabaseFactory().getDatabase();
  dataSource ??= SqfliteDatasource(_db!);

  localCache ??= LocalCache(EncryptedSharedPreferences(
      prefs: await SharedPreferences.getInstance(),
      mode: AESMode.gcm,
      randomKeyKey: 'Color#E2330'));
  userService ??= UserService(firestore);

  receiptService ??= ReceiptService(firestore);
  encryptionViewmodel ??= EncryptionViewmodel(
      EncryptionService(), dataSource!, localCache!, userService!);
  if (notificationService == null) {
    notificationService = AwesomeNotificationService(AwesomeNotifications());
    await notificationService!.initialize();
  }
  user ??= User.fromJSON(localCache!.fetch("USER"));
}

EncryptionViewmodel? encryptionViewmodel;
IMessageService? messageService;
IDataSource? dataSource;
ILocalCache? localCache;
IUserService? userService;
IReceiptService? receiptService;
INotificationService? notificationService;
Database? _db;
User? user;

class FirebaseNotifications {
  final FirebaseMessaging _firebaseMessaging;
  FirebaseNotifications(
      this._firebaseMessaging,
      User _user,
      IDataSource _dataSource,
      IMessageService _messageService,
      EncryptionViewmodel _encryptionViewmodel,
      IUserService _userService,
      ILocalCache _localCache,
      IReceiptService _receiptService,
      INotificationService _notificationService) {
    encryptionViewmodel = _encryptionViewmodel;
    notificationService = _notificationService;
    messageService = _messageService;
    localCache = _localCache;
    dataSource = _dataSource;
    user = _user;
    receiptService = _receiptService;
    userService = _userService;
  }
  Future<void> initNotifications() async {
    if (user?.id == null) {
      return;
    }
    await _firebaseMessaging
        .subscribeToTopic(user!.id!); //? Subscribing to listen to just my email
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    final fCMToken = await _firebaseMessaging.getToken();
    debugPrint(fCMToken);
    // GetMessages().setData(fCMTokenRegisteredName, fCMToken!);
    // _messageDatabaseHelper.initializeDatabase();

    FirebaseMessaging.onMessage.listen(_onMessageRecieved);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _onMessageRecieved(RemoteMessage message) async {
    debugPrint("Hello");
  }
}
