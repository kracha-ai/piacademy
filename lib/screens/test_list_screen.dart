import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/theme_notifier.dart';
import 'mock_test_screen.dart';
import 'home_screen.dart';

class TestListScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;
  final Map<String, List<String>> subjectToSectionsMap; // NEW: Receive this map

  const TestListScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
    required this.subjectToSectionsMap, // NEW: Required in constructor
  });

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {
  String? _currentUserId;
  List<String> _sectionsForSubject = []; // NEW: List to hold sections for the current subject

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadSectionsForSubject(); // NEW: Load sections when the screen initializes
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user!= null) {
      setState(() {
        _currentUserId = user.uid;
      });
    } else {
      print("No user logged in.");
    }
  }

  // NEW: Method to populate _sectionsForSubject
  void _loadSectionsForSubject() {
    setState(() {
      _sectionsForSubject = widget.subjectToSectionsMap[widget.subject]?? [];
    });
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
      body: Column( // Use Column to place sections above the StreamBuilder
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sectionsForSubject.isNotEmpty) // Display sections if available
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sections for ${widget.subject}:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0, // Space between chips
                    runSpacing: 8.0, // Space between lines of chips
                    children: _sectionsForSubject.map((sectionName) => Chip(
                      label: Text(sectionName),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13),
                    )).toList(),
                  ),
                  const Divider(height: 32), // Separator
                ],
              ),
            ),
          Expanded( // Ensure the ListView takes remaining space
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tests')
                  .where('exam', isEqualTo: widget.exam)
                  .where('topic', isEqualTo: widget.topic)
                  .where('subject', isEqualTo: widget.subject)
              // Optionally, add a.where('section', isEqualTo: selectedSection) here
              // if you implement a section filter in this screen.
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
                          .where('userId', isEqualTo: _currentUserId)
                          .where('testId', isEqualTo: testId)
                          .snapshots(),
                      builder: (context, resSnapshot) {
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
          ),
        ],
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