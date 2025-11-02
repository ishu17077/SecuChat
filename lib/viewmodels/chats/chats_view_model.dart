import 'package:chat/chat.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/viewmodels/chats/base_view_model.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

class ChatsViewModel extends BaseViewModel {
  final IDataSource _dataSource;
  final IUserService userService;
  final EncryptionViewmodel encryption;
  bool usersChecked = false;

  ChatsViewModel(this._dataSource,
      {required this.userService, required this.encryption})
      : super(_dataSource, userService);
  Future<List<Chat>> getChats() async {
    if (chats.isEmpty) chats = await _dataSource.findAllChats();
    //! Spawn isolates

    if (!usersChecked) {
      usersChecked = true;
      for (var chat in chats) {
        if (chat.from.id == null) {
          throw Exception("User id cannot be null in database");
        }
        //TODO: Fix this userService being called everytime

        userService.fetchUserId(chat.from.id!).then((user) {
          if (user == null) {
            throw Exception(
                "User not found, the user might have deleted its account");
          }
          _dataSource.updateUser(user);
          chat.from = user;
        });
      }
    }
    return chats;
  }

  Future<void> forceRefresh() async {
    final chats = await _dataSource.findAllChats();
    if (chats.length != this.chats.length) this.chats = chats;
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

    return await addMessage(localMessage);
  }
}
