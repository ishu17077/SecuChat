import 'package:flutter/material.dart';
import 'package:secuchat/unit_components.dart';

class AppSearchBar extends StatelessWidget {
  final String title;
  final Function(String) onChanged;
  const AppSearchBar({required this.title, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      showCursor: true,
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
