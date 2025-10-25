import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:equatable/equatable.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';
part 'message_event.dart';
part 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final IMessageService _messageService;
  StreamSubscription? _subscription;
  final EncryptionViewmodel _encryption;

  MessageBloc(this._messageService, this._encryption)
      : super(MessageState.initial()) {
    on<Subscribed>((event, emit) async {
      await _subscription?.cancel();
      _subscription = _messageService
          .messages(activeUser: event.user)
          .listen((message) => add(_MessageReceived(message)));
    });

    on<MessageSent>((event, emit) async {
      final nonEncryptedContents = event.message.contents;
      final encryptionKey = await _encryption.getChatAcmKey(event.message.to);
      if (event.message.iv != null && encryptionKey != null) {
        event.message.contents = await _encryption.encryption.encrypt(
            event.message.contents,
            event.message.iv!.bytes,
            encryptionKey.secretKey);
      }
      final message = await _messageService.send(event.message);
      message.contents = nonEncryptedContents;
      emit(MessageState.sent(message));
    });
    on<_MessageReceived>((event, emit) async {
      final encryptionKey = await _encryption.getChatAcmKey(event.message.from);
      if (event.message.iv != null && encryptionKey != null) {
        event.message.contents = await _encryption.encryption.decrypt(
            event.message.contents,
            event.message.iv!.bytes,
            encryptionKey.secretKey);
      }
      emit(MessageState.received(event.message));
    });
  }
  @override
  Future<void> close() {
    _subscription?.cancel();
    _messageService.dispose();
    return super.close();
  }
}
