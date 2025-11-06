import 'dart:async';
import 'dart:convert';
import 'package:chat/chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class TypingNotification implements ITypingNotification {
  final FirebaseDatabase _firebaseDatabase;
  final StreamController<TypingEvent> _controller =
      StreamController<TypingEvent>.broadcast();
  StreamSubscription? _changeFeed;

  TypingNotification(this._firebaseDatabase);

  @override
  void dispose() {
    _controller.close();
    _changeFeed?.cancel();
  }

  @override
  Future<void> send(TypingEvent event) async {
    final DatabaseReference docRef = _firebaseDatabase.ref("typing/");
    await docRef.child(event.to).set({event.from: event.event.value()});
  }

  @override
  Stream<TypingEvent> subscribe({required User user, List<String>? userIds}) {
    _changeFeed = _firebaseDatabase.ref("typing/${user.id!}").onValue.listen((
      event,
    ) {
      if (event.type != DatabaseEventType.childRemoved) {
        if (event.snapshot.value == null) return;
        final objdata = jsonEncode(event.snapshot.value);
        final data = jsonDecode(objdata) as Map<String, dynamic>;
        for (var userId in data.keys) {
          final TypingEvent event = TypingEvent(
            from: userId.toString(),
            to: user.id!,
            event: TypingParser.fromString(data[userId].toString()),
            time: DateTime.now(),
          );
          _controller.add(event);
          _deleteTypingEvent(event.to, event.from);
        }
      }
    });
    _changeFeed?.onError((error) {
      debugPrint(error.toString());
    });
    return _controller.stream;
  }

  // void _removingEvent(TypingEvent event) {
  //   _firebaseDatabase.collection("typing_events").doc(event.id).delete();
  // }

  TypingEvent _mapIdToTypingEvent(String id, Map<String, dynamic> event) {
    return TypingEvent.fromJSON({"id": id, ...event});
  }

  Future<void> _deleteTypingEvent(String receiver, String sender) async {
    await _firebaseDatabase
        .ref("typing/")
        .child(receiver)
        .child(sender)
        .remove();
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
