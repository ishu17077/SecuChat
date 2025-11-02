import 'package:chat/chat.dart';
import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';

class ChatPill extends StatelessWidget {
  final String? text;

  final ReceiptStatus receiptStatus;
  final bool isMe;
  final bool noMaginRequired;
  final bool isLastMessage;

  const ChatPill({
    super.key,
    required this.text,
    this.receiptStatus = ReceiptStatus.sent,
    this.noMaginRequired = false,
    this.isLastMessage = false,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: 6.5,
        right: 6.5,
        top: 1.0,
        bottom: noMaginRequired ? 1.0 : 10.0,
      ),
      child: Column(children: [
        Align(
          alignment: isMe ? Alignment.bottomRight : Alignment.bottomLeft,
          child: Container(
            constraints: BoxConstraints(
                minWidth: 0,
                maxWidth: MediaQuery.of(context).size.width * 0.62,
                minHeight: 28,
                maxHeight: double.infinity),
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 11.5),
            decoration: ShapeDecoration(
              color: isMe ? Colors.black45 : kSubHeadingColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide.none),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    text ?? '',
                    maxLines: 10,
                    textAlign: TextAlign.start,
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 5),
                Align(
                  alignment: Alignment.centerLeft,
                  child: isMe
                      ? receiptStatus == ReceiptStatus.read
                          ? const Icon(
                              Icons.done_all,
                              color: Colors.blue,
                              size: 12,
                            )
                          : const Icon(
                              Icons.done,
                              color: Colors.grey,
                              size: 17,
                            )
                      : const SizedBox(),
                )
              ],
            ),
          ),
        ),
        isLastMessage
            ? SizedBox(height: MediaQuery.of(context).size.height * 0.018)
            : const SizedBox(),
      ]),
    );
  }
}
