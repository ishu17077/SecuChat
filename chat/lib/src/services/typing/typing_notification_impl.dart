import 'dart:async';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TypingNotification implements ITypingNotification {
  final FirebaseFirestore _firebaseFirestore;
  final StreamController<TypingEvent> _controller =
      StreamController<TypingEvent>.broadcast();
  StreamSubscription? _changeFeed;

  TypingNotification(this._firebaseFirestore);

  @override
  void dispose() {
    _controller.close();
    _changeFeed?.cancel();
  }

  @override
  Future<bool> send(TypingEvent event) async {
    final DocumentReference docRef = await _firebaseFirestore
        .collection("typing_events")
        .add(event.toJSON());
    return docRef.id != null ? true : false;
  }

  @override
  Stream<TypingEvent> subscribe({required User user, List<String>? userIds}) {
    _changeFeed = _firebaseFirestore
        .collection("typing_events")
        // .where("from", arrayContains: userIds)
        .where("to", isEqualTo: user.id)
        .orderBy('time')
        .snapshots()
        .listen((event) {
          event.docChanges.forEach((element) {
            if (element.type == DocumentChangeType.added) {
              final data = element.doc.data();
              if (data == null) {
                return;
              }
              final event = _mapIdToTypingEvent(element.doc.id, data);
              _removingEvent(event);
              _controller.sink.add(event);
            }
          });
          return;
        });
    _changeFeed?.onError((error) {
      debugPrint(error.toString());
    });
    return _controller.stream;
  }

  void _removingEvent(TypingEvent event) {
    _firebaseFirestore.collection("typing_events").doc(event.id).delete();
  }

  TypingEvent _mapIdToTypingEvent(String id, Map<String, dynamic> event) {
    return TypingEvent.fromJSON({"id": id, ...event});
  }

  @override
  Future<void> pause() async {
    _changeFeed?.pause();
  }

  @override
  Future<void> resume() async {
    _changeFeed?.resume();
  }
}
