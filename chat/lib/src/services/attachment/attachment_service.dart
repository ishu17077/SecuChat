import 'dart:async';

import 'package:chat/src/models/attachment.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/attachment/attachment_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttachmentService implements IAttachment {
  final FirebaseFirestore _firestore;
  late final StreamController<Attachment> _controller;
  late final StreamSubscription _changeFeed;

  AttachmentService(this._firestore);

  @override
  Future<Attachment> send(Attachment attachment) async {
    late final Attachment attachmentReturn;
    try {
      final attachmentJson = attachment.toJson();
      DocumentReference<Map<String, dynamic>> docRef = await _firestore
          .collection("attachments")
          .add(attachmentJson)
          .timeout(Duration(seconds: 2));
      attachmentReturn = _mapIdToAttachment(docRef.id, attachmentJson);
    } catch (e) {
      debugPrint(e.toString());
      return attachment;
    }
    return attachmentReturn;
  }

  @override
  Stream<Attachment> attachments({required User activeUser}) {
    _startReceivingAttachments(activeUser);
    return _controller.stream;
  }

  void _startReceivingAttachments(User user) {
    _changeFeed = _firestore
        .collection("attachments")
        .where("to", isEqualTo: user.id)
        .snapshots()
        .listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
          snapshot.docChanges.forEach((doc) {
            switch (doc.type) {
              case DocumentChangeType.added:
                if (doc.doc.data() == null) {
                  _removeDeliveredAttachment(doc.doc.id)
                  return;
                }
                Attachment attachment = _mapIdToAttachment(
                  doc.doc.id,
                  doc.doc.data()!,
                );
                _controller.sink.add(attachment);
                _removeDeliveredAttachment(attachment.id!);
              default:
            }
            return;
          });
        });
    _changeFeed.onError((error) {
      debugPrint(error.toString());
    });
  }

  @override
  Future<List<Attachment>> getPendingAttachments({required User activeUser}) {
    
  }

  Future<List<Attachment>> _getLatestAttachments(User user) async{
    final querySnapshot = await _firestore.collection("attachments").where("to", isEqualTo: user.id).get();
    return querySnapshot.docs.map((doc) {
      return _mapIdToAttachment(doc.id, doc.data());
    }).toList();
  }

  @override
  Future<void> pause() async {
    _changeFeed.pause();
  }

  @override
  Future<void> resume() async {
    _changeFeed.resume();
  }

  @override
  void dispose() {
    _changeFeed.cancel();
    _controller.close();
  }

  Attachment _mapIdToAttachment(String id, Map<String, dynamic> attachment) {
    return Attachment.fromJson({"id": id, ...attachment});
  }

  Future<void> _removeDeliveredAttachment(String attachmentId) {
    return _firestore.collection("attachments").doc(attachmentId).delete();
  }
}
