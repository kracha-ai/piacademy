// main.dart - Entire corrected code block

import 'package:flutter/material.dart';
import 'package:piacademy/screens/login_screen.dart';
import 'package:piacademy/screens/pin_setup_screen.dart';
import 'package:piacademy/screens/home_screen.dart';
import 'package:piacademy/screens/pin_login_screen.dart'; // <--- ADD THIS IMPORT!
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'services/theme_notifier.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const PiAcademy(),
    ),
  );
}

class PiAcademy extends StatelessWidget {
  const PiAcademy({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PiAcademy',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[900],
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900],
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      themeMode: themeNotifier.themeMode,
      home: const AuthGate(),
    );
  }
}

// --- THIS IS THE AUTH GATE - IT STAYS IN MAIN.DART! ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If Firebase is still thinking, show a loading circle
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // 2. If NOT logged in (no user data), show the Login Screen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. If LOGGED IN, check if they have a PIN saved in the phone memory
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefSnapshot) {
            // Show loading indicator while SharedPreferences is being loaded
            if (prefSnapshot.connectionState == ConnectionState.waiting ||!prefSnapshot.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final String? savedPin = prefSnapshot.data!.getString('user_pin');

            // If no PIN is saved, or it's empty, go to PinSetupScreen
            if (savedPin == null || savedPin.isEmpty) {
              return const PinSetupScreen();
            } else {
              // If a PIN IS saved, go to the PinLoginScreen to verify it
              return const PinLoginScreen(); // <--- THIS IS THE ONLY LINE THAT CHANGES HERE!
            }
          },
        );
      },
    );
  }
}