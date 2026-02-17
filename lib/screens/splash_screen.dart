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
  late Animation<double> _fadeAnimation; // Single animation for both logo and text
  final String text = "Pi Academy";

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
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn), // Both fade in during the first half
      ),
    );

    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // --- MODIFIED NAVIGATION WITH LEFT-TO-RIGHT PUSH ANIMATION ---
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // This is the "left to right push" animation:
              // The new screen slides in from the right edge (1.0)
              // to its final position (0.0).
              const begin = Offset(1.0, 0.0); // Start from the right edge
              const end = Offset.zero;       // End at its default position
              const curve = Curves.elasticOut; // A nice smooth acceleration/deceleration

              // Create a Tween for the offset
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

              // Apply the SlideTransition
              return SlideTransition(
                position: animation.drive(tween),
                child: child, // The HomeScreen is the child here
              );
            },
            transitionDuration: const Duration(milliseconds: 2000), // How long the slide transition takes
          ),
        );
        // -----------------------------------------------------------
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Logo - centered and fading in with the shared animation
                Opacity(
                  opacity: _fadeAnimation.value,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 130,
                  ),
                ),
                // Text - centered below logo and fading in with the shared animation
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 180.0), // Keep your original padding for vertical alignment
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}