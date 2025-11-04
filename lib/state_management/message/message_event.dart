part of 'message_bloc.dart';

sealed class MessageEvent extends Equatable {
  const MessageEvent();

  factory MessageEvent.subscribed(User user) => Subscribed(user);
  factory MessageEvent.onMessageSent(LocalMessage message) =>
      MessageSend(message);
  factory MessageEvent.onMessageResend(LocalMessage message) =>
      MessageResend(message);

  @override
  List<Object?> get props => [];
}

class MessageResend extends MessageEvent {
  final LocalMessage message;
  const MessageResend(this.message);
  @override
  // TODO: implement props
  List<Object?> get props => [message];
}

class Subscribed extends MessageEvent {
  final User user;
  const Subscribed(this.user);

  @override
  List<Object?> get props => [user];
}

class MessageSend extends MessageEvent {
  final LocalMessage message;
  const MessageSend(this.message);
  @override
  List<Object?> get props => [message];
}

class _MessageReceived extends MessageEvent {
  final Message message;
  const _MessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}
