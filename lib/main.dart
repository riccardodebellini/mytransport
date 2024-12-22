import 'package:flutter/material.dart';
import 'package:mytransportation/pages/navigation.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange, brightness: MediaQuery.platformBrightnessOf(context))
      ),
      home: Navigation(),
    );
  }
}
