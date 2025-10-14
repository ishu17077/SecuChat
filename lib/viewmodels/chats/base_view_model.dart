import 'package:chat/chat.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:flutter/material.dart';

abstract class BaseViewModel {
  final IDataSource _dataSource;
  final IUserService _userService;
  List<Chat> chats = List.empty(growable: true);
  BaseViewModel(this._dataSource, this._userService);

  @protected
  Future<void> addMessage(LocalMessage message) async {
    assert(message.chatId != null || message.userId != null,
        "Both user_id and chat_id cannot be null");
    //? Caching technique not accessing db
    for (var chat in chats) {
      if (chat.userId == message.userId) {
        message.chatId = chat.id;
        chat.mostRecent = message;
        await _dataSource.addMessage(message);
        return;
      }
    }
    var chat = await _getChat(message.chatId, message.userId!, null);

    if (chat == null) {
      final User? user = await _userService.fetch(message.userId!);
      if (user == null) {
        debugPrint("Cannot find user for id ${message.userId}");
        return;
      }

      //TODO: Return chat id on successful chat creation in database
      await _createNewUser(user);
      int chatId = await _createNewChat(message.userId!, user);
      chat = Chat.fromJSON({"id": chatId, "user_id": message.userId});
      chat.from = user;
      chat.mostRecent = message;
      chats.add(chat);
    } else {
      chats.add(chat);
    }
    message.chatId = chat.id;
    await _dataSource.addMessage(message);
  }

  Future<Chat?> _getChat(
      //TODO: Future impl groups
      String? chatId,
      String? userId,
      String? groupId) async {
    assert(chatId != null || userId != null || groupId != null,
        "user_id and chat_id cannot be null");
    return await _dataSource.findChat(chatId: chatId, userId: userId);
  }

  Future<int> _createNewChat(String userId, User from) async {
    Chat chat = Chat(userId);
    return await _dataSource.addChat(chat);
  }

  Future<void> _createNewUser(User user) async {
    await _dataSource.addUser(user);
  }
}
