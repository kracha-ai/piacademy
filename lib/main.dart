import 'package:flutter/material.dart';
import 'package:piacademy/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. ADD THIS
import 'firebase_options.dart'; // 2. ADD THIS (The file we generated earlier)
import 'screens/splash_screen.dart';
import 'services/theme_notifier.dart';

// 3. CHANGE main() to be "Future<void>" and "async"
Future<void> main() async {
  // 4. ENSURE EVERYTHING IS READY BEFORE STARTING
  WidgetsFlutterBinding.ensureInitialized();

  // 5. START FIREBASE
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
        cardColor: Colors.white,
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
        cardColor: Colors.grey[800],
      ),
      themeMode: themeNotifier.themeMode,
      home: const LoginScreen(),
    );
  }
}