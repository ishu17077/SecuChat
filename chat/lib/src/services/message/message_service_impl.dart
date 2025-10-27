import 'dart:async';
import 'dart:math';
import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MessageService implements IMessageService {
  final FirebaseFirestore _firestore;
  // final IEncryption _encryption;
  final StreamController<Message> _controller =
      StreamController<Message>.broadcast();
  StreamSubscription? _changeFeed;

  MessageService(this._firestore);

  @override
  void dispose() {
    _changeFeed?.cancel();
    _controller.close();
  }

  @override
  Stream<Message> messages({required User activeUser}) {
    _startRecievingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<Message> send(Message message) async {
    late final Message messageReturn;
    DocumentReference<Map<String, dynamic>> docRef = await _firestore
        .collection("messages")
        .add(message.toJSON());
    messageReturn = _mapIdToMessage(docRef.id, message.toJSON());
    return messageReturn;
  }

  void _startRecievingMessages(User user) {
    _changeFeed = _firestore
        .collection("messages")
        .where("to", isEqualTo: user.id)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          snapshot.docChanges.forEach((element) async {
            switch (element.type) {
              case DocumentChangeType.added:
                if (element.doc.data() == null) {
                  return;
                }
                Message message = _mapIdToMessage(
                  element.doc.id,
                  element.doc.data()!,
                );

                _controller.sink.add(message);
                _removeDeliveredMessage(message);
              default:
            }
            return;
          });
        });

    _changeFeed?.onError((error) {
      debugPrint(error.toString());
    });
  }

  @override
  Future<List<Message>> getMessages({required User activeUser}) async {
    return await _getLatestMessages(activeUser);
  }

  Future<List<Message>> _getLatestMessages(User user) async {
    final messageMaps = await _firestore
        .collection("messages")
        .where("to", isEqualTo: user.id!)
        .get();
    return messageMaps.docChanges.map((messageMap) {
      return _mapIdToMessage(messageMap.doc.id, messageMap.doc.data()!);
    }).toList();
  }

  void _removeDeliveredMessage(Message message) {
    _firestore.collection("messages").doc(message.id).delete();
  }

  Message _mapIdToMessage(String id, Map<String, dynamic> messageMap) {
    return Message.fromJSON({"id": id, ...messageMap});
  }
}
