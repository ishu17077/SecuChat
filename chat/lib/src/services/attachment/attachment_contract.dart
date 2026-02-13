import 'package:chat/chat.dart';
import 'package:chat/src/models/attachment.dart';

abstract class IAttachment {
  Future<Attachment> send(Attachment attachment);
  Stream<Attachment> attachments({required User activeUser});
  Future<List<Attachment>> getPendingAttachments({required User activeUser});
  Future<void> pause();
  Future<void> resume();
  void dispose();
}
