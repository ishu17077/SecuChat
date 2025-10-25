import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class ChatTextField extends StatefulWidget {
  final Function onSendButtonPressed;
  final TextEditingController textEditingController;
  void Function(String text) onChanged;
  ChatTextField(
      {super.key,
      required this.onChanged,
      required this.onSendButtonPressed,
      required this.textEditingController});

  @override
  State<ChatTextField> createState() => _ChatTextFieldState();
}

class _ChatTextFieldState extends State<ChatTextField> {
  late final TextEditingController _textEditingController =
      widget.textEditingController;
  bool shouldKeyBoardAppear = false;
  String? contents;

  @override
  void dispose() {
    // TODO: implement dispose
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context)
                    .scaffoldBackgroundColor
                    .withValues(alpha: 0.0),
                Theme.of(context).scaffoldBackgroundColor
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(left: 10, right: 10),
          child: TextField(
            onTap: () {
              setState(() {
                shouldKeyBoardAppear = true;
              });
            },
            keyboardType: TextInputType.multiline,
            readOnly: !shouldKeyBoardAppear,
            controller: _textEditingController,
            minLines: 1,
            onChanged: widget.onChanged,
            showCursor: true,
            autofocus: true,
            maxLines: 5,
            style: TextStyle(color: Colors.white.withOpacity(0.9)),
            decoration: InputDecoration(
                fillColor: const Color.fromRGBO(76, 72, 90, 1),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.only(
                    left: 1.0, right: 1.0, top: 10.0, bottom: 10.0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none),
                prefixIcon: const Icon(
                  Icons.text_fields_outlined,
                  color: kSexyTealColor,
                ),
                suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: kSexyTealColor,
                    ),
                    onPressed: () {
                      widget.onSendButtonPressed(_textEditingController
                          .value.text
                          .trimRight()
                          .trimLeft());
                      contents = '';
                      _textEditingController.clear();
                    })),
          ),
        ),
      ],
    );
  }
}
