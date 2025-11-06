import 'package:chat/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:secuchat/models/chat.dart';
import 'package:secuchat/state_management/typing/typing_notif_bloc.dart';
import 'package:secuchat/unit_components.dart';

class ChatTile extends StatelessWidget {
  final Chat chat;
  final VoidCallback onTap;
  final int unread;
  const ChatTile(this.chat, {required this.onTap, this.unread = 0, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: kBackgroundColor,
      splashColor: kSexyTealColor.withValues(alpha: 0.2),
      leading: Hero(
        tag: chat.id,
        child: CircleAvatar(
          backgroundImage: NetworkImage(chat.from?.photoUrl ??
              'https://www.shutterstock.com/image-photo/red-text-any-questions-paper-600nw-2312396111.jpg'),
        ),
      ),
      trailing: unread != 0
          ? CircleAvatar(
              backgroundColor: Colors.red,
              maxRadius: 10,
              child: Text("$unread", textScaler: TextScaler.linear(0.7)),
            )
          : null,
      title: Text(
        chat.from?.name ?? '',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: BlocBuilder<TypingNotifBloc, TypingNotifState>(
        builder: (_, state) {
          //TODO: This implementaion doesn't need to be so big work on this
          if (state is TypingReceivedSuccess &&
              state.typingEvent.event == Typing.start &&
              state.typingEvent.from == chat.from?.id) {
            return Text(
              "typing...",
              style:
                  TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
            );
          } else if (state is TypingReceivedSuccess &&
              state.typingEvent.event == Typing.stop &&
              state.typingEvent.from == chat.from.id) {
            return Text(
              chat.mostRecent?.message.contents ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            );
          }

          return Text(
            chat.mostRecent?.message.contents ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          );
        },
      ),
      onTap: onTap,
      enabled: true,
      enableFeedback: true,
    );
  }
}
