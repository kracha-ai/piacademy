import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(PiAcademi());
}

class PiAcademi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiAcademi',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomeScreen(),
    );
  }
}
