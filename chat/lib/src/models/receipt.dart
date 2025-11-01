import 'package:cloud_firestore/cloud_firestore.dart';

enum ReceiptStatus { sent, delivered, read, sending }

extension ReceiptStatusParsing on ReceiptStatus {
  String value() => this.name;

  static fromString(String receiptStatus) {
    return ReceiptStatus.values.firstWhere(
      (element) => element.name == receiptStatus,
      orElse: () => ReceiptStatus.sent,
    );
  }
}

class Receipt {
  String get id => _id;
  final String messageId;
  final String recipientId;
  final ReceiptStatus status;
  final DateTime time;
  late String _id;

  Receipt({
    required this.messageId,
    required this.recipientId,
    required this.status,
    required this.time,
  });

  toJSON() => {
    "message_id": messageId,
    "recipient_id": recipientId,
    "status": status.value(),
    "time": time,
  };

  factory Receipt.fromJSON(Map<String, dynamic> map) {
    Receipt receipt = Receipt(
      messageId: map["message_id"]!,
      recipientId: map["recipient_id"],
      status: ReceiptStatusParsing.fromString(map["status"] ?? "sent"),
      time: (map["time"] is DateTime
          ? map["time"]
          : map["time"] is Timestamp
          ? (map["time"] as Timestamp).toDate()
          : DateTime.parse(map["time"]!)),
    );
    receipt._id = map["id"];
    return receipt;
  }
}
