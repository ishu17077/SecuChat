import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart';

class Attachment {
  String? _id;
  String? get id => _id;
  final DateTime time;
  final IV? iv;
  final String attachmentUrl;
  final String fileName;
  final String from;
  final String to;

  Attachment({
    required this.from,
    required this.time,
    required this.to,
    required this.attachmentUrl,
    required this.fileName,
    this.iv,
  });

  Map<String, dynamic> toJson() => {
    "time": time,
    "iv": iv?.base64,
    "attachment_url": attachmentUrl,
    "file_name": fileName,
    "from": from,
    "to": to,
  };

  factory Attachment.fromJson(Map<String, dynamic> imageMap) {
    return Attachment(
      from: imageMap["from"],
      time: imageMap["time"] is DateTime
          ? imageMap["time"]
          : imageMap["time"] is Timestamp
          ? (imageMap["time"] as Timestamp).toDate()
          : DateTime.parse(
              imageMap["time"] ?? DateTime.now().toIso8601String(),
            ),
      to: imageMap["to"],
      fileName: imageMap["file_name"],
      attachmentUrl: imageMap["attachment_url"],
    );
  }
}
