// lib/screens/pin_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  bool _isPinVisible = false;
  bool _isLoading = false;

  Future<void> _savePin() async {
    if (_isLoading) return;

    if (_pinController.text.length < 4 || _confirmPinController.text.length < 4) {
      _showError("Please fill both PIN fields");
      return;
    }

    if (_pinController.text!= _confirmPinController.text) {
      _showError("PINs do not match. Please try again.");
      _confirmPinController.clear(); // Clear confirm field so they can retry
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_pin', _pinController.text);

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // <--- Added this to allow Scaffold to resize
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[900]!, Colors.blue[600]!],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Icon(Icons.security_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 10),
            const Text(
              "Security Setup",
              style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Expanded( // <--- Added Expanded here
              child: SingleChildScrollView( // <--- Added SingleChildScrollView here
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    // mainAxisSize: MainAxisSize.min, // Optional: Can be added if needed, but Expanded usually handles it
                    children: [
                      const Text("Setup a 4-digit PIN for PiAcademy",
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 25),

                      _buildPinField(
                        controller: _pinController,
                        label: "New PIN",
                        showEye: true,
                        autoProceed: false, // Don't proceed on first box
                      ),

                      const SizedBox(height: 20),

                      _buildPinField(
                        controller: _confirmPinController,
                        label: "Confirm New PIN",
                        showEye: false,
                        autoProceed: true, // AUTO-PROCEED on the second box
                      ),

                      const SizedBox(height: 30),

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
                        onPressed: _savePin,
                        child: const Text("Set PIN & Finish", style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ), // <--- End of Expanded
          ],
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool showEye,
    required bool autoProceed,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText:!_isPinVisible,
      maxLength: 4,
      textAlign: TextAlign.center,
      onChanged: (value) {
        if (autoProceed && value.length == 4) {
          _savePin(); // Trigger save automatically when confirm box is full
        }
      },
      onSubmitted: (value) => _savePin(),
      style: const TextStyle(fontSize: 22, letterSpacing: 15, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        counterText: "",
        filled: true,
        fillColor: Colors.grey[100],
        prefixIcon: const Icon(Icons.lock_clock_outlined),
        suffixIcon: showEye? IconButton(
          icon: Icon(_isPinVisible? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isPinVisible =!_isPinVisible;
            });
          },
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}