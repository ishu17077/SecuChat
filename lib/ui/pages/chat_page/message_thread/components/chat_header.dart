import 'package:flutter/material.dart';

class ChatHeader extends StatelessWidget {
  final String username;
  final bool isTyping;

  const ChatHeader({
    super.key,
    required this.username,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          username,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
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
