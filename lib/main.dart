import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mytransportation/pages/navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Android EtE config.
   SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarContrastEnforced: false,
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
  ));

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: MediaQuery.platformBrightnessOf(context))
      ),
      home: Navigation(),
    );
  }
}
