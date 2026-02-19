import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Import provider for theme
import '../services/theme_notifier.dart'; // Import theme_notifier for theme
import 'mock_test_screen.dart';

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
  List<Map<String, dynamic>> testData = []; // Store full test data including file and name

  @override
  void initState() {
    super.initState();
    loadTests();
  }

  Future<void> loadTests() async {
    String folderPath =
        "assets/tests/${widget.exam}/${widget.topic}/${widget.subject}/";

    print("Checking folder: $folderPath");

    try {
      final jsonString = await rootBundle.loadString('${folderPath}tests.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> tests = jsonData["tests"];

      setState(() {
        testData = tests.map((test) {
          // Store both the file path and the display name
          return {
            'file': folderPath + (test["file"] as String),
            'name': test["name"]?? (test["file"] as String).split('/').last.replaceAll(".txt", ""),
            // Add other potential properties like description, difficulty, duration
            'description': test["description"]?? "No description available",
            'difficulty': test["difficulty"]?? "Easy", // Example default
            'duration': test["duration"]?? "60 min", // Example default
          };
        }).toList();
      });
    } catch (e) {
      print("Error loading tests from $folderPath: $e");
      // Handle the error, maybe show a snackbar or an error message to the user
      setState(() {
        testData = []; // Ensure list is empty on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    // Define text and UI colors that adapt to the theme for consistent look
    final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color iconColor = isDarkTheme? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} Tests"),
        // AppBar colors are handled by MaterialApp's AppBarTheme
      ),
      body: testData.isEmpty
          ? Center(
        child: Text(
          "No Tests Available. Check asset paths and JSON data.",
          style: TextStyle(fontSize: 16, color: textColor),
          textAlign: TextAlign.center,
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: testData.length,
        itemBuilder: (context, index) {
          final test = testData[index];
          String filePath = test['file'];
          String fileName = test['name'];
          String description = test['description'];
          String difficulty = test['difficulty'];
          String duration = test['duration'];

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            color: Theme.of(context).cardColor, // Use theme's card color
            child: InkWell(
              onTap: () async {
                String? selectedLanguage = await showDialog<String>(
                  context: context,
                  builder: (context) {
                    // Make the AlertDialog theme-aware
                    return AlertDialog(
                      backgroundColor: Theme.of(context).cardColor,
                      title: Text("Select Language", style: TextStyle(color: textColor)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, "en"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: isDarkTheme? Colors.black : Colors.white,
                              backgroundColor: isDarkTheme? Colors.white : Theme.of(context).primaryColor,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text("English"),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, "te"),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: isDarkTheme? Colors.black : Colors.white,
                              backgroundColor: isDarkTheme? Colors.white : Theme.of(context).primaryColor,
                              minimumSize: const Size(double.infinity, 40),
                            ),
                            child: const Text("తెలుగు"),
                          ),
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
                        testFile: filePath,
                        language: selectedLanguage,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 14, color: secondaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: secondaryTextColor),
                        const SizedBox(width: 4),
                        Text("Difficulty: $difficulty", style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                        const SizedBox(width: 16),
                        Icon(Icons.timer, size: 16, color: secondaryTextColor),
                        const SizedBox(width: 4),
                        Text("Duration: $duration", style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}