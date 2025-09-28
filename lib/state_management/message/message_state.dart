part of 'message_bloc.dart';

sealed class MessageState extends Equatable {
  const MessageState();

  factory MessageState.initial() => MessageInitial();

  factory MessageState.sent(Message message) => MessageSentSuccess(message);

  factory MessageState.received(Message message) =>
      MessageReceivedSuccess(message);

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class MessageSentSuccess extends MessageState {
  final Message message;
  const MessageSentSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class MessageReceivedSuccess extends MessageState {
  final Message message;
  const MessageReceivedSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
//TODO: implementation of failure in case of decryption failed and other issues
