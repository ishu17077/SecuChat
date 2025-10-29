import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';

abstract class IMessageService {
  Future<Message> send(Message message);
  Stream<Message> messages({required User activeUser});
  Future<List<Message>> getMessages({required User activeUser});
  Future<void> pause();
  Future<void> resume();
  void dispose();
}
