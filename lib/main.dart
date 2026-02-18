import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import the provider package
import 'screens/splash_screen.dart'; // Your existing SplashScreen
import 'services/theme_notifier.dart'; // Import your ThemeNotifier

void main() {
  runApp(
    // Wrap your entire app with ChangeNotifierProvider to make ThemeNotifier available
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(), // Create an instance of your ThemeNotifier
      child: const PiAcademy(), // Your main app widget
    ),
  );
}

class PiAcademy extends StatelessWidget {
  const PiAcademy({super.key}); // Added const for best practice

  @override
  Widget build(BuildContext context) {
    // Listen to the ThemeNotifier to get the current theme mode
    // This will cause MaterialApp to rebuild when themeMode changes
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiAcademy',
      // --- THEME DEFINITIONS ---
      theme: ThemeData(
        brightness: Brightness.light, // Explicitly define for light theme
        primarySwatch: Colors.blue, // Using blue as the primary color for light mode
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[900], // Dark blue AppBar for light theme
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        scaffoldBackgroundColor: Colors.white, // White background for light mode
        cardColor: Colors.white, // White cards for light mode
        // Define other light theme properties here
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark, // Explicitly define for dark theme
        primarySwatch: Colors.blue, // You can use a different primary for dark
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900], // Darker AppBar for dark theme
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        scaffoldBackgroundColor: Colors.grey[900], // Dark background
        cardColor: Colors.grey[800], // Dark cards
        // Define other dark theme properties here
      ),
      // --- Apply the theme mode from your notifier ---
      themeMode: themeNotifier.themeMode,
      // ---------------------------------------------
      home: SplashScreen(),
    );
  }
}