import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:encrypt/encrypt.dart';
import 'package:equatable/equatable.dart';
import 'package:secuchat/models/local_message.dart';
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

    on<MessageSend>((event, emit) async {
      emit(MessageSending(event.message.message));
      final nonEncryptedContents = event.message.message.contents;
      event.message.message.iv = IV.fromSecureRandom(16);
      final encryptionKey =
          await _encryption.getChatAcmKey(event.message.message.to);
      if (event.message.message.iv != null && encryptionKey != null) {
        event.message.message.contents = await _encryption.encryption.encrypt(
            event.message.message.contents,
            event.message.message.iv!.bytes,
            encryptionKey.secretKey);
      }
      event.message.message = await _messageService.send(event.message.message);
      event.message.message.contents = nonEncryptedContents;
      if (event.message.message.id != null) {
        emit(MessageSentSuccess(event.message));
        return;
      }
      emit(MessageSentFailed(event.message));
    });

    on<MessageResend>((event, emit) async {
      final nonEncryptedContents = event.message.message.contents;
      final encryptionKey =
          await _encryption.getChatAcmKey(event.message.message.to);
      if (event.message.message.iv != null && encryptionKey != null) {
        event.message.message.contents = await _encryption.encryption.encrypt(
            event.message.message.contents,
            event.message.message.iv!.bytes,
            encryptionKey.secretKey);
      }
      event.message.message = await _messageService.send(event.message.message);

      if (event.message.message.id != null &&
          event.message.message.id!.isNotEmpty) {
        event.message.message.contents = nonEncryptedContents;
        emit(MessageResendSuccess(event.message));
        return;
      }
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

  Future<void> pause() async {
    await _messageService.pause();
    // _subscription?.pause();
  }

  Future<void> resume() async {
    await _messageService.resume();
    // _subscription?.resume();
  }
}
