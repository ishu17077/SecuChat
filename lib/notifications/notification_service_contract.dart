import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';

@pragma("vm:entry-point")
abstract class INotificationService {
  Future<void> initialize();
  Future<void> createTempNotif(int id);
  Future<void> removeChatNotification(String chatId);
  Future<void> createNotification(Chat chat, LocalMessage message);
  Future<void> cancel(int id);
   @pragma("vm:entry-point")
  Future<void> cancelAll();
}
