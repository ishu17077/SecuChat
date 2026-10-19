import 'package:chat/src/models/attachment.dart';
import 'package:chat/src/models/message_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';

class Message {
  String? get id => _id;
  final String from;
  final String to;
  String
  contents; //! for attachments content will be divided in two strings seperated by ;
  final MessageType type;
  String? parentMessageId;
  final DateTime time;
  IV? iv;
  Attachment? attachment;
  String? _id;

  Message({
    required this.from,
    required this.to,
    required this.contents,
    required this.time,
    this.type = MessageType.text,
    this.iv,
    this.parentMessageId,
    this.attachment,
  });

  Map<String, dynamic> toJSON() => {
    "from": from,
    "to": to,
    "contents": contents,
    "time": time,
    "iv": iv?.base64,
    "parent_message_id": parentMessageId,
    "attachment": attachment?.toJson(),
  };

  factory Message.fromJSON(Map<String, dynamic> map) {
    Message message = Message(
      iv: map["iv"] != null ? IV.fromBase64(map["iv"]!) : null,
      from: map["from"]!,
      to: map["to"]!,
      contents: map["contents"],
      type: MessageTypeParsing.fromString(map["type"] ?? 'text'),
      time: (map["time"] is DateTime
          ? map["time"]
          : map["time"] is Timestamp
          ? (map["time"] as Timestamp).toDate()
          : DateTime.parse(map["time"] ?? DateTime.now().toIso8601String())),
      parentMessageId: map["parent_message_id"],
      attachment: map["attachment"] != null
          ? Attachment.fromJson(map["attachment"])
          : null,
    );
    message._id = map["id"];
    return message;
  }
}
