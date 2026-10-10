import 'dart:async';

import 'package:chat/src/models/attachment.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/attachment/attachment_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AttachmentService implements IAttachmentService {
  AttachmentService(Dio dio);

  @override
  Future<Attachment> send(Attachment attachment) async {
    late final Attachment attachmentReturn;
    try {} catch (e) {}
  }

  Future<void> removeDeliveredAttachment(String attachmentId) {
    return _firestore.collection("attachments").doc(attachmentId).delete();
  }
}
