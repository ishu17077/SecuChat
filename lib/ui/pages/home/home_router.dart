import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:secuchat/viewmodels/encryption/encryption_viewmodel.dart';

abstract class IHomeRouter {
  Future<void> onShowMessageThread(BuildContext context, User receiver, User me,
      EncryptionViewmodel encryption,
      {String? chatId});
  Future<void> onShowNewChatUi(
      BuildContext context, User me, EncryptionViewmodel encryption);
}

class HomeRouter implements IHomeRouter {
  final Widget Function(User receiver, User me, EncryptionViewmodel encryption,
      {String? chatId}) showMessageThread;
  final Widget Function(User me, EncryptionViewmodel encryption) showNewChatUi;
  HomeRouter(this.showMessageThread, this.showNewChatUi);

  @override
  Future<void> onShowMessageThread(BuildContext context, User receiver, User me,
      EncryptionViewmodel encryption,
      {String? chatId}) {
    return Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                showMessageThread(receiver, me, encryption, chatId: chatId)));
  }

  @override
  Future<void> onShowNewChatUi(
      BuildContext context, User me, EncryptionViewmodel encryption) {
    return Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => showNewChatUi(me, encryption),
        ));
  }
}
