import 'package:chat/chat.dart';
import 'package:encrypt/encrypt.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/state_management/receipt/receipt_bloc.dart';
import 'package:secuchat/viewmodels/chats/base_view_model.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
import 'package:webcrypto/webcrypto.dart';

class ChatViewModel extends BaseViewModel {
  String? chatId;
  final IDataSource _dataSource;
  final IUserService _userService;
  List<LocalMessage> messages = List.empty(growable: true);
  int otherMessages = 0;

  ChatViewModel(this._dataSource, this._userService)
      : super(_dataSource, _userService);

  Future<List<LocalMessage>> getMessages(String chatId) async {
    //! Cache Layer
    if (messages.isNotEmpty) {
      return messages;
    }
    messages = await _dataSource.findMessages(chatId);
    if (messages.isNotEmpty) chatId = chatId;
    return messages;
  }

  Future<void> forceRefresh(String chatId) async {
    final messages = await _dataSource.findMessages(chatId);
    if (messages.length != this.messages.length) this.messages = messages;
  }

  Future<void> sentMessage(Message message, {ReceiptStatus? status}) async {
    LocalMessage localMessage = LocalMessage(
        message,
        Receipt(
          messageId: message.id ?? '',
          recipientId: message.to,
          status: status ?? ReceiptStatus.sent,
          time: DateTime.now(),
        ),
        userId: message.to);
    if (chatId != null) {
      int id = await _dataSource.addMessage(localMessage);
      localMessage = _mapIdToLocalMessage(localMessage, id);

      for (final chat in chats) {
        if (chat.from.id! == message.to) {
          chat.mostRecent = localMessage;
          chat.messages.add(localMessage);
        }
      }

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
        status: ReceiptStatus.read,
        time: DateTime.now(),
      ),
      userId: message.from,
    );

    //! CAUTION: Rare conflict if chatId is null, but shouldn't be the case
    chatId ??= localMessage.chatId;

    if (localMessage.chatId != chatId) {
      otherMessages++;
    }
    for (var chat in chats) {
      if (chat.id == chatId) {
        chat.unread = 0;
        break;
      }
    }
    messages.insert(0, localMessage);
    await addMessage(localMessage);
  }

  Future<void> updateMessageReceipt(Receipt receipt,
      {String? localMessageId}) async {
    //TODO: Impl receipts wrong Impl
    //receipt.messageId is serverId
    if (localMessageId != null) {
      for (LocalMessage message in messages) {
        if (message.id == localMessageId) {
          message.receipt = receipt;
          break;
        }
      }
      await _dataSource.updateMessageReceipt(receipt.messageId, receipt.status,
          localMessageId: localMessageId);
      return;
    }

    for (LocalMessage message in messages) {
      if (message.message.id == receipt.messageId) {
        message.receipt = receipt;
        break;
      }
    }
    await _dataSource.updateMessageReceipt(receipt.messageId, receipt.status);
  }

  LocalMessage _mapIdToLocalMessage(LocalMessage localMessage, int id) {
    return LocalMessage.fromJSON({...localMessage.toJSON(), "id": id});
  }
}
