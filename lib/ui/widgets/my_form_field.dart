import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';

class MyFormField extends StatefulWidget {
  final String? infoBox;
  final TextInputType keyBoardType;
  final VoidCallback? onPressed;
  final IconData? prefixIcon;
  final Icon? suffixIcon;
  final int? formField;
  final double? heightFactor;
  final Function(bool) onFocusChanged;
  final bool obscureText;
  final TextEditingController? textEditingController;
  final String? Function(String?)? validator;

  const MyFormField(
      {super.key,
      this.infoBox = '',
      this.keyBoardType = TextInputType.none,
      required this.onPressed,
      this.obscureText = false,
      required this.prefixIcon,
      required this.onFocusChanged,
      required this.textEditingController,
      required this.validator,
      required this.suffixIcon,
      this.heightFactor,
      required this.formField});

  @override
  State<MyFormField> createState() => _MyFormFieldState();
}

class _MyFormFieldState extends State<MyFormField> {
  bool isClicked = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
        widget.onFocusChanged(value);
        setState(() {
          value ? isClicked = true : isClicked = false;
        });
      },
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            color: isClicked ? kTextFieldColor : Colors.transparent,
          ),
          padding: const EdgeInsets.only(top: 0, bottom: 0, left: 12),
          height: MediaQuery.of(context).size.height *
              (widget.heightFactor ?? 1) *
              0.075,
          width: MediaQuery.of(context).size.width * 0.85,
          child: TextFormField(
            style: const TextStyle(color: Colors.white),
            autovalidateMode: AutovalidateMode.always,
            controller: widget.textEditingController,
            decoration: InputDecoration(
              isDense: true,
              labelText: widget.infoBox,

              labelStyle: const TextStyle(
                color: Colors.white54,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: Colors.white54,
              ),

              suffixIcon: widget.suffixIcon,

              border: InputBorder.none,
              focusedBorder: const UnderlineInputBorder(
                // borderRadius: BorderRadius.circular(25.0),
                borderSide: BorderSide.none,
              ),
              // errorBorder: OutlineInputBorder(
              //     borderRadius: BorderRadius.circular(25.0),
              //     borderSide: const BorderSide(
              //         strokeAlign: -100, color: Colors.redAccent, width: 0)),
              errorStyle: const TextStyle(
                height: 0,
                fontSize: 0,
              ),
              errorBorder: InputBorder.none,
            ),
            onFieldSubmitted: (value) {
              FocusScope.of(context).nextFocus();
            },
            textInputAction: widget.formField == 4
                ? TextInputAction.done
                : TextInputAction.next,
            onTap: widget.onPressed,
            keyboardType: widget.keyBoardType,
            obscureText: widget.obscureText,
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}
