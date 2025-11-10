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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'SecuChat',
      theme: ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        primarySwatch: greenAndroid,
        buttonTheme: const ButtonThemeData(
          buttonColor: Color(0xff0cf3e1),
        ),
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => CompositionRoot.start(),
        "/manage-storage": (_) => CompositionRoot.composeManageStorageUi(),
      },
    );
  }
}
