import 'package:chat/chat.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/viewmodels/chats/base_view_model.dart';

class ChatViewModel extends BaseViewModel {
  String? chatId;
  final IDataSource _dataSource;
  final IUserService _userService;
  List<LocalMessage> messages = List.empty(growable: true);
  int otherMessages = 0;

  ChatViewModel(this._dataSource, this._userService)
      : super(_dataSource, _userService);

  Future<List<LocalMessage>> getMessages(String chatId) async {
    if (messages.isNotEmpty) {
      return messages;
    }
    messages = await _dataSource.findMessages(chatId);
    if (messages.isNotEmpty) chatId = chatId;
    return messages;
  }

  Future<void> sentMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
        message,
        Receipt(
          messageId: message.id!,
          recipientId: message.to,
          status: ReceiptStatus.sent,
          time: DateTime.now(),
        ),
        userId: message.to);
    if (chatId != null) {
      int id = await _dataSource.addMessage(localMessage);
      //TODO: map id to local message
      this.messages.add(localMessage);
      return;
    }
    //TODO: Transition from chat_id to user_id
    messages.insert(0, localMessage);
    await addMessage(localMessage);
  }

  Future<void> recieveMessage(Message message) async {
    LocalMessage localMessage = LocalMessage(
      message,
      Receipt(
        messageId: message.id!,
        recipientId: message.to,
        status: ReceiptStatus.sent,
        time: DateTime.now(),
      ),
      userId: message.from,
    );
    //! CAUTION: Rare conflict if chatId is null, but shouldn't be the case
    chatId ??= localMessage.chatId;
    if (localMessage.chatId != chatId) {
      otherMessages++;
    }
    messages.insert(0, localMessage);
    await addMessage(localMessage);
  }

  Future<void> updateMessageReceipt(Receipt receipt) async {
    //TODO: Impl receipts wrong Impl
    //receipt.messageId is serverId
    await _dataSource.updateMessageReceipt(receipt.messageId, receipt.status);
  }
}
