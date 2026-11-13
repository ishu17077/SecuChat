import 'package:secuchat/data/constants/table_names.dart';
import 'package:chat/chat.dart';

class LocalMessage {
  String? chatId;
  String? userId;
  String get id => _id!;
  String? _id;
  Message message;
  Receipt receipt;
  bool isDecrypted;
  Message? parentMessage;

  LocalMessage(this.message, this.receipt,
      {this.chatId, this.userId, this.isDecrypted = true, this.parentMessage})
      : assert(chatId != null || userId != null,
            "Both user_id and chat_id cannot be null");

  Map<String, dynamic> toJSON() {
    assert(message.id == null || receipt.status != ReceiptStatus.sending,
        "Message server id cannot be null while receipt was sent");
    return {
      MessageTable.colChatId: chatId,
      MessageTable.colSender: message.from,
      MessageTable.colRecipient: message.to,
      MessageTable.colContents: message.contents,
      MessageTable.colServerId: message.id,
      //TODO: Impl this
      MessageTable.colParentMessageId: null,
      MessageTable.colIsDecrypted: isDecrypted ? 0 : 1,
      MessageTable.colExecutedAt: receipt.time.toString(),
      MessageTable.colReceipt: receipt.status.value(),
      MessageTable.colCreatedAt: message.time.toString(),
    };
  }

  factory LocalMessage.fromJSON(Map<String, dynamic> messageMap) {
    // assert(
    //     messageMap[MessageTable.colServerId] == null ||
    //         ReceiptStatusParsing.fromString(messageMap["receipt"]) ==
    //             ReceiptStatus.sending,
    //     "Message server id cannot be null while receipt was sent");
    final Message message = Message.fromJSON({
      "id": messageMap[MessageTable.colServerId] ?? '',
      "from": messageMap[MessageTable.colSender] ?? '',
      "to": messageMap[MessageTable.colRecipient] ?? '',
      "status": messageMap[MessageTable.colReceipt] ?? ReceiptStatus.sent,
      "contents": messageMap[MessageTable.colContents] ?? '',
      "time": messageMap["created_at"] != null
          ? DateTime.parse(messageMap["created_at"])
          : DateTime.now(),
    });
    final LocalMessage localMessage = LocalMessage(
      message,

      //TODO receipt time
      Receipt(
        messageId: message.id ?? "${messageMap["id"]}",
        recipientId: message.to,
        //TODO: Impl
        time: DateTime.tryParse(messageMap[MessageTable.colExecutedAt] ?? '') ??
            DateTime.now(),
        status: ReceiptStatusParsing.fromString(
            messageMap[MessageTable.colReceipt] ?? 'sent'),
      ),
      chatId: messageMap[MessageTable.colChatId],
      isDecrypted: messageMap[MessageTable.colIsDecrypted] == 0 ? false : true,
      //TODO: Impl ParentMessage
    );
    localMessage._id = "${messageMap["id"]}";
    return localMessage;
  }
}
