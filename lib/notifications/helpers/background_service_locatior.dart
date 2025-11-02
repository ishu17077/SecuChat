import 'package:chat/chat.dart';
import 'package:secuchat/cache/local_cache.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/notifications/notification_service_contract.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class BackgroundServiceLocator {
  static BackgroundServiceLocator? _instance;

  EncryptionViewmodel? encryptionViewmodel;
  IMessageService? messageService;
  IDataSource? datasource;
  ILocalCache? localCache;
  IUserService? userService;
  IReceiptService? receiptService;
  INotificationService? notificationService;
  User? user;

  BackgroundServiceLocator._();

  static BackgroundServiceLocator get instance {
    _instance ??= BackgroundServiceLocator._();
    return _instance!;
  }
}
