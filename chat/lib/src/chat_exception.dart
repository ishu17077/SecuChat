import 'package:chat/chat.dart';
import 'package:chat/src/models/attachment.dart';

sealed class ChatException implements Exception {
  final String? msg;
  ChatException([this.msg]);
}

class MesssageSentFailed extends ChatException {
  final Message message;
  MesssageSentFailed(this.message, [super.msg]);
}

class MessageReceivedFailed extends ChatException {}

class AttachmentSendFailed extends ChatException {
  final Attachment attachment;
  final AttachmentErrorType errorType;
  AttachmentSendFailed(this.attachment, this.errorType, [super.msg]);
}

enum AttachmentErrorType {
  internalServerError("INTERNAL_SERVER_ERROR"),
  fileSizeLimitExceeded("FILE_SIZE_LIMIT_EXCEEDED"),
  fileNotSupported("FILE_NOT_SUPPORTED"),
  uploadError("UPLOAD_ERROR"),
  unknownError("UNKNOWN_ERROR");

  final String value;
  const AttachmentErrorType(this.value);
}
