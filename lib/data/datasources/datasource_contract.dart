import 'package:chat/chat.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';

abstract class IDataSource {
  Future<int> addChat(Chat chat);
  Future<int> addMessage(LocalMessage message);
  Future<Chat?> findChat({String? chatId, String? userId});
  Future<bool> chatExists({String? chatId, String? userId});
  Future<List<Chat>> findAllChats();
  Future<void> updateMessage(LocalMessage message);
  Future<List<LocalMessage>> findMessages(String chatId);
  Future<void> deleteChat(String chatId);
  Future<void> updateMessageReceipt(String messageId, ReceiptStatus status,
      {String? localMessageId});
  Future<User?> findUser(String userId);
  Future<int> addUser(User user);
  Future<void> updateUser(User user);
  Future<void> deleteUser(String userId);
}
