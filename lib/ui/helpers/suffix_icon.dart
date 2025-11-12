import 'package:flutter/material.dart';
import 'package:secuchat/unit_components.dart';

Icon? suffixIcon(String text, String? Function(String? value) validator) {
  if (text.isEmpty) return null;
  if (validator(text) != null) {
    return redCross;
  }
  return greenCheckMark;
}
