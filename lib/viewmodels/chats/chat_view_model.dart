import 'package:chat/chat.dart';
import 'package:encrypt/encrypt.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/models/local_message.dart';
import 'package:secuchat/state_management/receipt/receipt_bloc.dart';
import 'package:secuchat/viewmodels/chats/base_view_model.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
import 'package:webcrypto/webcrypto.dart';

class ChatViewModel {
  String? chatId;
  List<LocalMessage> messages = List.empty(growable: true);

  int otherMessages = 0;
  final BaseViewModel baseViewModel;
  List<Chat> get chats => baseViewModel.chats;
  ChatViewModel(this.baseViewModel);

  Future<List<LocalMessage>> getMessages(String chatId) async {
    //! Cache Layer
    if (messages.isNotEmpty) {
      return messages;
    }
    messages = await baseViewModel.dataSource.findMessages(chatId);
    if (messages.isNotEmpty) chatId = chatId;
    return messages;
  }

  Future<void> forceRefresh(String chatId) async {
    final messages = await baseViewModel.dataSource.findMessages(chatId);
    if (messages.length != this.messages.length) this.messages = messages;
  }

  Future<String> sentMessage(Message message, {ReceiptStatus? status}) async {
    LocalMessage localMessage = LocalMessage(
        message,
        Receipt(
          messageId: message.id ?? '',
          recipientId: message.to,
          status: status ?? ReceiptStatus.sent,
          time: DateTime.now(),
        ),
        userId: message.to);
    chatId ??= localMessage.chatId;
    for (final chat in baseViewModel.chats) {
      if (chat.from.id! == message.to) {
        chat.mostRecent = localMessage;
        chat.unread = 0;
        chat.messages.add(localMessage);
        chatId = chat.id;
      }
    }
    localMessage.chatId = chatId;
    if (localMessage.chatId != null) {
      int id = await baseViewModel.dataSource.addMessage(localMessage);
      localMessage = _mapIdToLocalMessage(localMessage, "$id");

      this.messages.insert(0, localMessage);
      return localMessage.id;
    }
    //TODO: Transition from chat_id to user_id

    final id =
        await baseViewModel.addMessage(localMessage, currentChatId: chatId);
    localMessage = _mapIdToLocalMessage(localMessage, id);
    messages.insert(0, localMessage);
    return id;
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

    messages.insert(0, localMessage);
    await baseViewModel.addMessage(localMessage, currentChatId: chatId);
  }

  Future<void> updateMessageReceipt(Receipt receipt,
      {String? localMessageId, Message? sMessage}) async {
    //TODO: Impl receipts wrong Impl
    //receipt.messageId is serverId
    if (localMessageId != null) {
      assert(sMessage != null, "Sever Message cannot be null");
      for (LocalMessage message in messages) {
        if (message.id == localMessageId) {
          message.receipt = receipt;
          message.message = sMessage!;
          break;
        }
      }
      await baseViewModel.dataSource.updateMessageReceipt(
          receipt.messageId, receipt.status,
          localMessageId: localMessageId);
      return;
    }

    for (LocalMessage message in messages) {
      if (message.message.id == receipt.messageId) {
        message.receipt = receipt;
        break;
      }
    }
    await baseViewModel.dataSource
        .updateMessageReceipt(receipt.messageId, receipt.status);
  }

  LocalMessage _mapIdToLocalMessage(LocalMessage localMessage, String id) {
    return LocalMessage.fromJSON({...localMessage.toJSON(), "id": id});
  }
}
