import 'package:flutter/material.dart';
import 'package:secuchat/ui/pages/chat_page/message_thread/components/typing_indicator.dart';

class ChatHeader extends StatelessWidget {
  final String username;
  final bool isTyping;

  const ChatHeader({
    Key? key,
    required this.username,
    required this.isTyping,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          username,
          style: const TextStyle(color: Colors.white70),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(height: 0),
          secondChild: const Text(
            "typing...",
            style: TextStyle(
                color: Colors.green, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          crossFadeState:
              isTyping ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }
}
