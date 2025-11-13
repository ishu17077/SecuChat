import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';

class MyFormField extends StatefulWidget {
  final String? infoBox;
  final TextInputType keyBoardType;
  final IconData? prefixIcon;
  final Icon? suffixIcon;
  final int? formField;
  final double? heightFactor;
  final StateSetter? parentSetState;
  final bool obscureText;
  final bool disabled;
  final TextEditingController? textEditingController;
  final String? Function(String?)? validator;

  const MyFormField(
      {super.key,
      this.infoBox = '',
      this.keyBoardType = TextInputType.none,
      this.obscureText = false,
      this.parentSetState,
      required this.prefixIcon,
      required this.textEditingController,
      required this.validator,
      required this.suffixIcon,
      this.heightFactor,
      required this.formField,
      this.disabled = false});

  @override
  State<MyFormField> createState() => _MyFormFieldState();
}

class _MyFormFieldState extends State<MyFormField> {
  bool isClicked = false;

  @override
  void initState() {
    if (widget.parentSetState != null && widget.textEditingController != null) {
      widget.textEditingController!.addListener(
        () {
          widget.parentSetState!(() {});
        },
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (value) {
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
            enabled: !widget.disabled,
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
                color: Colors.red,
              ),
              errorBorder: InputBorder.none,
            ),
            onFieldSubmitted: (value) {
              FocusScope.of(context).nextFocus();
            },
            textInputAction: widget.formField == 4
                ? TextInputAction.done
                : TextInputAction.next,
            keyboardType: widget.keyBoardType,
            obscureText: widget.obscureText,
            validator: widget.validator,
          ),
        ),
      ),
    );
  }
}
