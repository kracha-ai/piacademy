// lib/screens/pin_login_screen.dart (changes are mostly in the build method)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:piacademy/screens/home_screen.dart'; // Import your home screen

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  String? _correctPin;

  @override
  void initState() {
    super.initState();
    _loadCorrectPin();
  }

  Future<void> _loadCorrectPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _correctPin = prefs.getString('user_pin');
    });
  }

  void _verifyPin() async {
    if (_isLoading || _correctPin == null) return;

    if (_pinController.text.length < 4) {
      _showSnackBar("Please enter the 4-digit PIN.");
      return;
    }

    setState(() => _isLoading = true);

    if (_pinController.text == _correctPin) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
        );
      }
    } else {
      _showSnackBar("Incorrect PIN. Please try again.");
      _pinController.clear();
    }

    setState(() => _isLoading = false);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if keyboard is open
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- Top Content ---
              Padding(
                // Reduce top padding when keyboard is open
                padding: EdgeInsets.only(
                  top: isKeyboardOpen? 40.0 : 100.0, // Smaller top padding if keyboard is open
                  bottom: isKeyboardOpen? 5.0 : 10.0, // Smaller bottom padding if keyboard is open
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lock_open_rounded,
                      size: isKeyboardOpen? 50 : 80, // Smaller icon if keyboard is open
                      color: Colors.white,
                    ),
                    SizedBox(height: isKeyboardOpen? 10 : 20), // Smaller space
                    Text(
                      "Welcome Back!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isKeyboardOpen? 20 : 28, // Smaller text
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isKeyboardOpen? 5 : 10), // Smaller space
                    Text(
                      "Enter your 4-digit PIN to proceed.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: isKeyboardOpen? 14 : 16, // Smaller text
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isKeyboardOpen? 20 : 40), // Adjust this space dynamically too

              // --- Bottom Content (the form) ---
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      "PIN Verification",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: isKeyboardOpen? 15 : 30), // Smaller space
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      obscureText: true,
                      onChanged: (value) {
                        if (value.length == 4) {
                          _verifyPin();
                        }
                      },
                      onSubmitted: (value) => _verifyPin(),
                      style: const TextStyle(
                        fontSize: 24,
                        letterSpacing: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        counterText: "",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: isKeyboardOpen? 15 : 30), // Smaller space
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      onPressed: _verifyPin,
                      child: const Text("Verify PIN", style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        _showSnackBar("Forgot PIN not implemented yet.");
                      },
                      child: Text(
                        "Forgot PIN?",
                        style: TextStyle(
                            color: Colors.blue[900], fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Only add bottom padding if keyboard is NOT open, to avoid adding extra space
                    // at the bottom of the scrollable area when it's already constrained.
                    if (!isKeyboardOpen) const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }
}