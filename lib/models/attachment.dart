import 'package:chat/chat.dart';
import 'package:secuchat/data/constants/table_names.dart';

class LocalAttachment {
  String get id => _id;
  late String _id;
  final String fileLocation;
  final String fileName;
  final MessageType fileType;
  final String messageId;

  LocalAttachment(
      {required this.fileLocation,
      required this.fileName,
      required this.fileType,
      required this.messageId});

  Map<String, dynamic> toJson() => {
        AttachmentTable.colFileLocation: fileLocation,
        AttachmentTable.colFileName: fileName,
        AttachmentTable.colFileType: fileType,
        AttachmentTable.colMessageId: messageId,
      };

  factory LocalAttachment.fromJson(Map<String, dynamic> map) {
    final localAttachment = LocalAttachment(
        fileLocation: map[AttachmentTable.colFileLocation],
        fileName: map[AttachmentTable.colFileName],
        fileType:
            MessageTypeParsing.fromString(map[AttachmentTable.colFileType]),
        messageId: map[AttachmentTable.colMessageId]);
    localAttachment._id = "${map["id"]}";
    return localAttachment;
  }
}
