import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

const Color kBackgroundColor = Color(0xff201a30);
const kTextFieldColor = Color.fromRGBO(133, 130, 141, 0.45);
const Icon greenCheckMark = Icon(
  Icons.check_circle_outline_outlined,
  color: Colors.greenAccent,
);
const Icon redCross = Icon(
  Icons.close,
  color: Colors.redAccent,
);
const Color kSexyTealColor = Color(0xff0cf3e1);
const Color kSubHeadingColor = Color.fromRGBO(133, 130, 141, 0.6);
final RegExp phoneRegExp = RegExp(r'^-?(([0-9]*)|(([0-9]*)\.([0-9]*)))$');
final RegExp emailRegExp = RegExp(
    r"^((([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+(\.([a-z]|\d|[!#\$%&'\*\+\-\/=\?\^_`{\|}~]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])+)*)|((\x22)((((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(([\x01-\x08\x0b\x0c\x0e-\x1f\x7f]|\x21|[\x23-\x5b]|[\x5d-\x7e]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(\\([\x01-\x09\x0b\x0c\x0d-\x7f]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF]))))*(((\x20|\x09)*(\x0d\x0a))?(\x20|\x09)+)?(\x22)))@((([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|\d|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))\.)+(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])|(([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])([a-z]|\d|-|\.|_|~|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])*([a-z]|[\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF])))$");
final RegExp nameRegExp = RegExp(r"^[A-Za-z\s]{1,}[]{0,1}[A-Za-z]{0,}$");
const String fCMTokenRegisteredName = 'FCM_Token';
final Future<Directory> directory = getApplicationDocumentsDirectory();
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey(debugLabel: "Main Navigator");
const MaterialColor greenAndroid = MaterialColor(0xff3ddc84, <int, Color>{
  50: Color(0xff37c677),
  100: Color(0xff31b06a),
  200: Color(0xff2b9a5c),
  300: Color(0xff25844f),
  400: Color(0xff1f6e42),
  500: Color(0xff185835),
  600: Color(0xff124228),
  700: Color(0xff0c2c1a),
  800: Color(0xff06160d),
  900: Color(0xff000000),
});
