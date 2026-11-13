import 'package:chat/src/models/attachment.dart';

abstract class IAttachmentService {
  Future<Attachment> send(
    Attachment attachment, {
    void Function(int sent, int total)? onProgress,
  });
}
