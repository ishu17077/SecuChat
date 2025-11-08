import 'package:chat/chat.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:flutter/material.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class BaseViewModel {
  final IDataSource dataSource;
  final IUserService userService;
  List<Chat> chats = [];
  BaseViewModel(this.dataSource, this.userService);

  Future<String> addMessage(LocalMessage message,
      {String? currentChatId}) async {
    assert(message.chatId != null || message.userId != null,
        "Both user_id and chat_id cannot be null");
    //? Caching technique not accessing db
    for (var chat in chats) {
      if (chat.userId == message.userId) {
        message.chatId = chat.id;
        chat.mostRecent = message;
        chat.messages.add(message);
        chat.unread = currentChatId == chat.id ? chat.unread : chat.unread + 1;
        chats.remove(chat);
        chats.insert(0, chat);
        int id = await dataSource.addMessage(message);
        return "$id";
      }
    }
    Chat? chat = await _getChat(userId: message.userId!);
    if (chat == null) {
      final User? user = await userService.fetchUserId(message.userId!);
      if (user == null) {
        debugPrint("Cannot find user for id ${message.userId}");
        return "";
      }

      //TODO: Return chat id on successful chat creation in database
      await _createNewUser(user);
      int chatId = await _createNewChat(message.userId!, user);
      chat = Chat.fromJSON({"id": chatId, "user_id": message.userId});
      chat.from = user;
      chat.mostRecent = message;
    }
    message.chatId = chat.id;
    chats.insert(0, chat);
    int id = await dataSource.addMessage(message);
    return "$id";
  }

  Future<Chat?> _getChat(
      //TODO: Future impl groups
      {String? chatId,
      String? userId,
      String? groupId}) async {
    assert(chatId != null || userId != null || groupId != null,
        "user_id and chat_id cannot be null");
    return await dataSource.findChat(chatId: chatId, userId: userId);
  }

  Future<int> _createNewChat(String userId, User from) async {
    Chat chat = Chat(userId);
    return await dataSource.addChat(chat);
  }

  Future<void> _createNewUser(User user) async {
    await dataSource.addUser(user);
  }
}
