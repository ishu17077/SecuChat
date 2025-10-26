import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:secuchat/composition_root.dart';
import 'package:secuchat/unit_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await CompositionRoot.configure();
  runApp(const MyApp());
  FlutterDisplayMode.setHighRefreshRate();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  final MaterialColor greenAndroid =
      const MaterialColor(0xff3ddc84, <int, Color>{
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
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SecuChat',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: greenAndroid,
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xff0cf3e1),
        ),
      ),
      home: CompositionRoot.start(),
    );
  }
}
