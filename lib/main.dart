import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';


void main() {
  runApp(PiAcademy());
}

class PiAcademy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiAcademy',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: SplashScreen(),
    );
  }
}
