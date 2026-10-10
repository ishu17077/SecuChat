import 'package:chat/chat.dart';
import 'package:chat/src/models/attachment.dart';

abstract class IAttachmentService {
  Future<Attachment> send(Attachment attachment);
}
