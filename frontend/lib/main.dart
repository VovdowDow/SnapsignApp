import 'package:flutter/material.dart';
import 'screens/WelcomeScreen.dart';
import 'screens/TranslateScreen.dart';

void main() {
  runApp(SnapSignApp());
}

class SnapSignApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SnapSign',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Prompt',
      ),
      home: WelcomeScreen(),
      
    );
  }
}
