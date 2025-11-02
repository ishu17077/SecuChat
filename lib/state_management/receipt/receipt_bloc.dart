import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:chat/chat.dart';
import 'package:secuchat/data/datasources/datasource_contract.dart';
import 'package:equatable/equatable.dart';

part 'receipt_event.dart';
part 'receipt_state.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  final IReceiptService _receiptService;
  StreamSubscription? _subscription;
  ReceiptBloc(this._receiptService) : super(ReceiptInitial()) {
    on<Subscribed>((event, emit) {
      _subscription =
          _receiptService.receipts(user: event.user).listen((receipt) {
        add(_ReceiptReceived(receipt));
      });
    });
    on<ReceiptSent>((event, emit) async {
      await _receiptService.send(event.receipt);
      emit(ReceiptState.sent(event.receipt));
    });

    on<_ReceiptReceived>((event, emit) {
      emit(ReceiptState.received(event.receipt));
    });
  }
  @override
  Future<void> close() {
    _receiptService.dispose();
    _subscription?.cancel();
    return super.close();
  }

  Future<void> pause() async {
    _receiptService.pause();
  }

  Future<void> resume() async {
    _receiptService.resume();
  }
}
