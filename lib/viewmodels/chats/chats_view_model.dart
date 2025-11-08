import 'package:chat/chat.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/viewmodels/chats/base_view_model.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class ChatsViewModel {
  final EncryptionViewmodel encryption;
  final BaseViewModel baseViewModel;
  List<Chat> get chats => baseViewModel.chats;
  bool usersChecked = false;

  ChatsViewModel(this.baseViewModel, {required this.encryption});
  Future<List<Chat>> getChats() async {
    if (baseViewModel.chats.isEmpty) {
      baseViewModel.chats = await baseViewModel.dataSource.findAllChats();
    }
    //! Spawn isolates

    if (!usersChecked) {
      usersChecked = true;
      for (var chat in baseViewModel.chats) {
        if (chat.from.id == null) {
          throw Exception("User id cannot be null in database");
        }
        //TODO: Fix this userService being called everytime

        baseViewModel.userService.fetchUserId(chat.from.id!).then((user) {
          if (user == null) {
            throw Exception(
                "User not found, the user might have deleted its account");
          }
          baseViewModel.dataSource.updateUser(user);
          chat.from = user;
        });
      }
    }
    return baseViewModel.chats;
  }

  Future<void> forceRefresh() async {
    final chats = await baseViewModel.dataSource.findAllChats();
    if (chats.length != baseViewModel.chats.length) baseViewModel.chats = chats;
  }

  Future<void> receivedMessage(String userId, Message message) async {
    LocalMessage localMessage = LocalMessage(
        message,
        Receipt(
            messageId: message.id ?? '',
            recipientId: userId,
            status: ReceiptStatus.delivered,
            time: DateTime.now()),
        userId: userId);

    await baseViewModel.addMessage(localMessage);
   
    return;
  }
}
