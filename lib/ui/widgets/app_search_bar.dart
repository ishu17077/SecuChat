import 'package:flutter/material.dart';
import 'package:secuchat/unit_components.dart';

class AppSearchBar extends StatelessWidget {
  final String title;
  final Function(String) onChanged;
  final FocusNode? focusNode;
  const AppSearchBar(
      {required this.title,
      required this.onChanged,
      this.focusNode,
      super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      showCursor: true,
      autofocus: false,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: title,
        contentPadding: EdgeInsets.zero,
        fillColor: kTextFieldColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.teal),
        labelStyle: TextStyle(color: Colors.white),
      ),
      cursorColor: Colors.teal,
      style: TextStyle(color: Colors.white),
      onChanged: onChanged,
    );
  }
}
