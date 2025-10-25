import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';

class Message {
  String? get id => _id;
  final String from;
  final String to;
  String contents;
  final DateTime time;
  final IV? iv;
  String? _id;

  Message({
    required this.from,
    required this.to,
    required this.contents,
    required this.time,
    this.iv,
  });

  toJSON() => {
    "from": from,
    "to": to,
    "contents": contents,
    "time": time,
    "iv": iv?.base64,
  };

  factory Message.fromJSON(Map<String, dynamic> map) {
    Message message = Message(
      iv: map["iv"] != null ? IV.fromBase64(map["iv"]!) : null,
      from: map["from"]!,
      to: map["to"]!,
      contents: map["contents"],
      time: (map["time"] is DateTime
          ? map["time"]
          : map["time"] is Timestamp
          ? (map["time"] as Timestamp).toDate()
          : DateTime.parse(map["time"] ?? DateTime.now().toIso8601String())),
    );
    message._id = map["id"];

    return message;
  }
}
