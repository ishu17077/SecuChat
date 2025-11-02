import 'dart:async';

import 'package:chat/src/models/receipt.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/receipt/receipt_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ReceiptService implements IReceiptService {
  final FirebaseFirestore _firebaseFirestore;
  final StreamController<Receipt> _controller =
      StreamController<Receipt>.broadcast();
  StreamSubscription? _changeFeed;

  ReceiptService(this._firebaseFirestore);

  @override
  void dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  @override
  Future<Receipt> send(Receipt receipt) async {
    DocumentReference docRef = await _firebaseFirestore
        .collection("receipts")
        .add(receipt.toJSON());
    return _mapIdToMessage(docRef.id, receipt.toJSON());
  }

  @override
  Stream<Receipt> receipts({required User user}) {
    _changeFeed = _firebaseFirestore
        .collection("receipts")
        .where("recipient_id", isEqualTo: user.id)
        .snapshots()
        .listen((querySnapshot) {
          querySnapshot.docChanges.forEach((element) {
            switch (element.type) {
              case DocumentChangeType.added:
                if (element.doc.data() == null) {
                  return;
                }
                final Receipt receipt = _mapIdToMessage(
                  element.doc.id,
                  element.doc.data()!,
                );

                _controller.sink.add(receipt);
                _removeDeliveredReceipt(receipt);
              default:
            }
            return;
          });
        });
    _changeFeed?.onError((error) {
      debugPrint(error);
    });
    return _controller.stream;
  }

  Receipt _mapIdToMessage(String id, Map<String, dynamic> receipt) {
    return Receipt.fromJSON({"id": id, ...receipt});
  }

  void _removeDeliveredReceipt(Receipt receipt) {
    _firebaseFirestore.collection("receipts").doc(receipt.id).delete();
  }

  Future<void> pause() async {
    _changeFeed?.pause();
  }

  Future<void> resume() async {
    _changeFeed?.resume();
  }
}
