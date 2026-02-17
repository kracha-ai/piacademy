import 'dart:math';
import 'package:flutter/material.dart';
import 'home_screen.dart'; // Make sure this import path matches where your HomeScreen is located!

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation; // <-- Declared here
  late Animation<double> _scaleAnimation;
  final String text = "Pi Academy"; // <-- Declared here

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Define a single fade animation for both logo and text,
    // making them appear together during the first half of the total duration.
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Define scale animation: starts at 0.8 scale, ends at 1.0 scale
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward(); // This should be called once

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // --- MODIFIED NAVIGATION WITH LEFT-TO-RIGHT PUSH ANIMATION ---
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.elasticOut;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 2000),
          ),
        );
        // -----------------------------------------------------------
      }
    });
  } // <-- This is the correct closing brace for initState

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Ensure the gradient background from previous classy look
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF42A5F5)], // Deep blue to a vibrant blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column( // Use Column to stack logo and text vertically
                mainAxisAlignment: MainAxisAlignment.center, // Center vertically
                children: [
                  // Logo with Opacity and new ScaleTransition
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale( // Apply the scale animation here
                      scale: _scaleAnimation.value,
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 150,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing between logo and text
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.5,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black26,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}