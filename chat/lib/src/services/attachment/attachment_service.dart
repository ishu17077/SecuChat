import 'dart:async';

import 'package:chat/src/chat_exception.dart';
import 'package:chat/src/models/attachment.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/attachment/attachment_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class AttachmentService implements IAttachmentService {
  final Dio _dio;
  AttachmentService(this._dio);

  /// Throws [AttachmentSendException] if the string is invalid
  @override
  Future<Attachment> send(
    Attachment attachment,
   { void Function(int sent, int total)? onProgress}
  ) async {
    try {
      final res = await _dio.post(
        "/send/attachment",
        data: attachment.toJson(),
        onSendProgress: onProgress,
      );
      if (res.statusCode == 200) {
        return attachment;
      }
      throw Exception();
    } on DioException catch (e) {
      AttachmentErrorType? attachmentErrorType;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
        case DioExceptionType.transformTimeout:
          attachmentErrorType = AttachmentErrorType.uploadError;
          break;
        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:
          attachmentErrorType = AttachmentErrorType.unknownError;
          break;
        case DioExceptionType.badResponse:
          if (e.response?.statusCode == 415) {
            attachmentErrorType = AttachmentErrorType.fileNotSupported;
          } else if (e.response?.statusCode == 413) {
            attachmentErrorType = AttachmentErrorType.fileSizeLimitExceeded;
          } else {
            attachmentErrorType = AttachmentErrorType.internalServerError;
          }
      }
      throw AttachmentSendFailed(attachment, attachmentErrorType);
    } catch (e) {
      throw AttachmentSendFailed(attachment, AttachmentErrorType.unknownError);
    }

  }

  Future getAttachment(
    String url,
    void Function(int received, int total) onProgress,
  ) async {
    final res = await _dio.get(url, onReceiveProgress: onProgress);
  }
}
