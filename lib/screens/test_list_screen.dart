import 'dart:convert'; // Not strictly needed for this file after removing local JSON, but often used.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- NEW: Import Firebase Auth

import '../services/theme_notifier.dart';
import 'mock_test_screen.dart';
import 'home_screen.dart';

class TestListScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;

  const TestListScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
  });

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  String? _currentUserId; // <--- NEW: Variable to hold the current user's ID

  @override
  void initState() {
    super.initState();
    _getCurrentUser(); // <--- NEW: Call method to get user ID on init
  }

  // <--- NEW: Method to fetch the current user's ID
  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user!= null) {
      setState(() {
        _currentUserId = user.uid;
      });
    } else {
      // Handle cases where no user is logged in
      // For now, we'll just print a message.
      // In a real app, you might want to redirect to a login screen
      // or show a specific message to the user.
      print("No user logged in.");
      // You might set _currentUserId to a "guest" identifier if anonymous usage is allowed,
      // but keep in mind guest results won't be tied to a specific persistent user.
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} Tests"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false, // Clears the backstack
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tests')
            .where('exam', isEqualTo: widget.exam)
            .where('topic', isEqualTo: widget.topic)
            .where('subject', isEqualTo: widget.subject)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}", style: TextStyle(color: Colors.red)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<QueryDocumentSnapshot> docs = snapshot.data?.docs?? [];

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No Tests Available in Firestore for this subject.",
                style: TextStyle(fontSize: 16, color: textColor),
                textAlign: TextAlign.center,
              ),
            );
          }

          // If _currentUserId is null, we can't reliably check completion status.
          // Display a loading indicator or a message until user ID is available.
          if (_currentUserId == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading user data to check test status..."),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String testId = docs[index].id;

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('results')
                    .where('userId', isEqualTo: _currentUserId) // <--- UPDATED: Use the actual _currentUserId
                    .where('testId', isEqualTo: testId)
                    .snapshots(),
                builder: (context, resSnapshot) {
                  // Check if any results documents exist for this user and test
                  bool isCompleted = resSnapshot.hasData && resSnapshot.data!.docs.isNotEmpty;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    color: Theme.of(context).cardColor,
                    child: InkWell(
                      onTap: () => _handleTestSelection(context, data, isDarkTheme, textColor),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['name']?? 'Untitled Test',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                ),
                                if (isCompleted)
                                  const Row(
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                                      SizedBox(width: 4),
                                      Text("Completed", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['description']?? 'No description available',
                              style: TextStyle(fontSize: 14, color: secondaryTextColor),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.star, size: 16, color: secondaryTextColor),
                                const SizedBox(width: 4),
                                Text("${data['difficulty']?? 'Medium'}", style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                                const SizedBox(width: 16),
                                Icon(Icons.timer, size: 16, color: secondaryTextColor),
                                const SizedBox(width: 4),
                                Text("${data['durationMinutes']?? '60'} min", style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                                const Spacer(),
                                // --- Visual indication of action ---
                                Text(
                                  isCompleted? "Re-take" : "Start Now",
                                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 14, color: Theme.of(context).primaryColor),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleTestSelection(BuildContext context, Map<String, dynamic> data, bool isDarkTheme, Color textColor) async {
    String? selectedLanguage = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text("Select Language", style: TextStyle(color: textColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _languageButton(context, "English", "en", isDarkTheme),
              const SizedBox(height: 10),
              _languageButton(context, "తెలుగు", "te", isDarkTheme),
            ],
          ),
        );
      },
    );

    if (selectedLanguage!= null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MockTestScreen(
            exam: widget.exam,
            topic: widget.topic,
            subject: widget.subject,
            testData: data,
            language: selectedLanguage,
          ),
        ),
      );
    }
  }

  Widget _languageButton(BuildContext context, String label, String code, bool isDark) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context, code),
      style: ElevatedButton.styleFrom(
        foregroundColor: isDark? Colors.black : Colors.white,
        backgroundColor: isDark? Colors.white : Theme.of(context).primaryColor,
        minimumSize: const Size(double.infinity, 45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }
}