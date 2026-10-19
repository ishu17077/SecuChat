import 'dart:async';
import 'dart:math';
import 'package:chat/chat.dart' hide User;
import 'package:chat/src/models/attachment.dart';
import 'package:firebase_auth/firebase_auth.dart' as FAuth;
import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MessageService implements IMessageService {
  final FirebaseFirestore _firestore;
  late final FAuth.User user;
  final StreamController<Message> _controller =
      StreamController<Message>.broadcast();
  StreamSubscription? _changeFeed;
  late final Dio _dio;
  final String serverUrl;
  late final String? token;

  MessageService(this._firestore, this.serverUrl){
    assert(FAuth.FirebaseAuth.instance.currentUser != null, "Cannot instantiate FirebaseMessageService without FirebaseAuth Sign In");
    user = FAuth.FirebaseAuth.instance.currentUser!;
    _dio = Dio(BaseOptions(baseUrl: serverUrl));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async{
        token = await user.getIdToken();
        if(token != null){
          options.headers["Authorization"] = "Bearer $token";
        }else{
          throw Exception("Cannot instantiate without token auth");
        }
      return handler.next(options);
    },
    //? Firebase automatically refresh its tokens if it doesn't the user is already signed out and also if you want to create retry instantiate new dio client and send its response in handler.resolve(response) use newDio.fetch
    onError: (error, handler) {
      if(error.response?.statusCode == 401){
        FAuth.FirebaseAuth.instance.signOut();
      }
      handler.next(error);
    },
    ),
    );
  }

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
    assert(
      message.type != MessageType.text && message.attachment != null,
      "Attachment cannot be null when message type is not text",
    )                             ;

    if (message.type != MessageType.text && message.attachment != null) {
      _dio.post("/upload", data: {});
    }

    late final Message messageReturn;
    try {
      var messageJson = message.toJSON();
      DocumentReference<Map<String, dynamic>> docRef = await _firestore
          .collection("messages")
          .add(messageJson)
          .timeout(Duration(seconds: 2));
      messageReturn = _mapIdToMessage(docRef.id, message.toJSON());
    } catch (e) {
      debugPrint(e.toString());
      return message;
    }
    return messageReturn;
  }

  void _startRecievingMessages(User user) {
    _changeFeed = _firestore
        .collection("messages")
        .where("to", isEqualTo: user.id)
        .orderBy('time', descending: false)
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
                _removeDeliveredMessage(message.id!);
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
  Future<List<Message>> getPendingMessages({required User activeUser}) async {
    return await _getLatestMessages(activeUser);
  }

  Future<List<Message>> _getLatestMessages(User user) async {
    final messageMaps = await _firestore
        .collection("messages")
        .where("to", isEqualTo: user.id!)
        .orderBy('time', descending: false)
        .get();
    return messageMaps.docs.map((doc) {
      _removeDeliveredMessage(doc.id);
      return _mapIdToMessage(doc.id, doc.data()!);
    }).toList();
  }

  void _removeDeliveredMessage(String id) async {
    try {
      await _firestore.collection("messages").doc(id).delete();
    } catch (e) {
      
    }
  }

  Message _mapIdToMessage(String id, Map<String, dynamic> messageMap) {
    return Message.fromJSON({"id": id, ...messageMap});
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
