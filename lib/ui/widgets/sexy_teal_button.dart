import 'package:flutter/material.dart';
import 'package:secuchat/unit_components.dart';

class SexyTealButton extends StatefulWidget {
  final String text;
  final Future<void> Function()? onPressed;
  const SexyTealButton({super.key, required this.text, this.onPressed});

  @override
  State<SexyTealButton> createState() => _SexyTealButtonState();
}

class _SexyTealButtonState extends State<SexyTealButton> {
  bool isLoading = false;
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(kSexyTealColor),
        minimumSize: WidgetStateProperty.all(Size(
            MediaQuery.of(context).size.width * 0.55,
            MediaQuery.of(context).size.height * 0.075)),
        elevation: WidgetStateProperty.all(5.0),
        shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(35))),
      ),
      onPressed: () async {
        if (widget.onPressed != null && !isLoading) {
          setState(() {
            isLoading = true;
          });

          await widget.onPressed!();
          setState(() {
            isLoading = false;
          });
        }
      },
      child: isLoading
          ? CircularProgressIndicator()
          : Text(
              widget.text.toUpperCase(),
              style: TextStyle(
                color: kBackgroundColor,
                fontSize: 15,
              ),
            ),
    );
  }
}
