import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:equatable/equatable.dart';

part 'typing_notif_event.dart';
part 'typing_notif_state.dart';

class TypingNotifBloc extends Bloc<TypingNotifEvent, TypingNotifState> {
  final ITypingNotification _typingNotification;
  StreamSubscription? _subscription;

  TypingNotifBloc(this._typingNotification) : super(TypingInitial()) {
    on<Subscribed>((event, emit) {
      _subscription?.cancel();
      _subscription =
          _typingNotification.subscribe(user: event.user).listen((typingEvent) {
        add(_TypingEventReceived(typingEvent));
      });
    });

    on<TypingEventSent>((event, emit) async {
      await _typingNotification.send(event.typingEvent);
      emit(TypingSentSuccess(event.typingEvent));
    });

    on<_TypingEventReceived>((event, emit) {
      emit(TypingReceivedSuccess(event.typingEvent));
    });
  }
  @override
  Future<void> close() async {
    _subscription?.cancel();
    _typingNotification.dispose();
    return super.close();
  }

  Future<void> pause() async {
    _typingNotification.pause();
  }

  Future<void> resume() async {
    _typingNotification.resume();
  }
}
