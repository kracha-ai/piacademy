import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import provider for theme
import '../services/theme_notifier.dart'; // Import theme_notifier for theme
import 'test_list_screen.dart'; // Assuming this file exists

class SubjectScreen extends StatefulWidget { // Changed to StatefulWidget for potential future state
  final String examName;
  final String topicName;

  const SubjectScreen({
    super.key,
    required this.examName,
    required this.topicName,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  // Mock data for subjects, including descriptions and completion
  // In a real app, this would be fetched based on examName and topicName
  List<Map<String, dynamic>> _allSubjects = [];

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    // This logic dynamically loads subjects based on the topicName
    // You can expand this with more complex data fetching/mapping
    if (widget.topicName == "GS") {
      _allSubjects = [
        {
          "name": "Polity",
          "description": "Indian Constitution, governance, public administration.",
          "completion": 0.70,
          "color": Colors.purple, // MaterialColor
        },
        {
          "name": "Geography",
          "description": "Physical, Human, and Economic Geography of India and World.",
          "completion": 0.55,
          "color": Colors.cyan, // MaterialColor
        },
        {
          "name": "Economics",
          "description": "Indian Economy, economic development, budgeting.",
          "completion": 0.62,
          "color": Colors.indigo, // MaterialColor
        },
      ];
    } else if (widget.topicName == "Science") {
      _allSubjects = [
        {
          "name": "Physics",
          "description": "Fundamental laws of nature, mechanics, electricity.",
          "completion": 0.75,
          "color": Colors.red, // MaterialColor
        },
        {
          "name": "Chemistry",
          "description": "Composition, structure, properties, and reactions of matter.",
          "completion": 0.68,
          "color": Colors.limeAccent, // Changed to Colors.limeAccent to demonstrate AccentColor handling
        },
        {
          "name": "Biology",
          "description": "Study of life, organisms, evolution, and ecosystems.",
          "completion": 0.81,
          "color": Colors.greenAccent, // MaterialAccentColor
        },
      ];
    } else {
      // Default subjects for other topics, or fetch from a service
      _allSubjects = [
        {
          "name": "General Subject 1",
          "description": "A general subject covering various aspects.",
          "completion": 0.40,
          "color": Colors.grey, // MaterialColor
        },
        {
          "name": "General Subject 2",
          "description": "Another general subject for broader knowledge.",
          "completion": 0.0,
          "color": Colors.brown, // MaterialColor
        },
      ];
    }
    // You could also add a setState here if _allSubjects is loaded asynchronously
    // setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    // Define text and UI colors that adapt to the theme for consistent look
    final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color placeholderColor = isDarkTheme? Colors.blue.shade300 : Colors.blue.shade800;
    final Color progressTrackColor = isDarkTheme? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);
    final Color progressValueColor = isDarkTheme? Colors.lightGreen.shade400 : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.examName} - ${widget.topicName}"),
        // AppBar colors are handled by MaterialApp's AppBarTheme
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allSubjects.length, // Use _allSubjects length
        itemBuilder: (context, index) {
          final subject = _allSubjects[index];
          final String subjectName = subject['name'];
          final String description = subject['description'];
          final double completion = subject['completion'];

          // --- FIX START ---
          final dynamic subjectBaseColor = subject['color']; // Get the base color

          Color cardColor;
          if (subjectBaseColor is MaterialAccentColor) {
            // For accent colors, pick a shade that is guaranteed to exist (e.g., 200 or 400)
            cardColor = isDarkTheme? subjectBaseColor.shade400 : subjectBaseColor.shade100;
          } else if (subjectBaseColor is MaterialColor) {
            // For regular MaterialColors, use shade100/700
            cardColor = isDarkTheme? subjectBaseColor.shade700 : subjectBaseColor.shade100;
          } else {
            // Fallback for any other unexpected color type
            cardColor = isDarkTheme? Colors.grey.shade700 : Colors.grey.shade100;
          }
          // --- FIX END ---

          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16), // Consistent margin
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15), // Consistent border radius
            ),
            color: cardColor, // Dynamic card color
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestListScreen(
                      exam: widget.examName,
                      topic: widget.topicName,
                      subject: subjectName,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Subject Name ---
                    Text(
                      subjectName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor, // Dynamic text color
                      ),
                    ),
                    const SizedBox(height: 4),
                    // --- Subject Description ---
                    Text(
                      description,
                      style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor), // Dynamic text color
                    ),
                    const SizedBox(height: 16),

                    // --- Progress Bar and Completion ---
                    if (completion > 0)...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: completion,
                          minHeight: 8,
                          backgroundColor: progressTrackColor, // Dynamic color
                          valueColor: AlwaysStoppedAnimation<Color>(progressValueColor), // Dynamic color
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Completed: ${(completion * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: textColor), // Dynamic text color
                      ),
                    ] else...[
                      // --- Show a "Start Learning" message if no progress ---
                      Text(
                        "Start exploring this subject!",
                        style: TextStyle(
                            color: placeholderColor,
                            fontWeight: FontWeight.w500), // Dynamic text color
                      )
                    ]
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