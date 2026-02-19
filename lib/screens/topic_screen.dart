import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import 'subject_screen.dart';

class TopicScreen extends StatefulWidget {
  final String examName;

  const TopicScreen({super.key, required this.examName});

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  // Corrected Mock data for topics - store MaterialColor swatches
  final List<Map<String, dynamic>> _allTopics = [
    {
      "name": "Aptitude",
      "description": "Numerical ability, data interpretation, logical reasoning.",
      "subtopics": "Quantitative, DI, Data Sufficiency",
      "completion": 0.65,
      "color": Colors.orange, // NOW, this refers to the MaterialColor SWATCH
    },
    {
      "name": "Reasoning",
      "description": "Verbal and non-verbal reasoning, puzzles, series.",
      "subtopics": "Verbal, Non-Verbal, Puzzles",
      "completion": 0.72,
      "color": Colors.teal, // MaterialColor SWATCH
    },
    {
      "name": "GS", // General Studies
      "description": "History, Geography, Polity, Economy, Science & Tech.",
      "subtopics": "History, Geo, Polity, Eco, S&T",
      "completion": 0.58,
      "color": Colors.green, // MaterialColor SWATCH
    },
    {
      "name": "English",
      "description": "Grammar, Vocabulary, Comprehension, Sentence Rearrangement.",
      "subtopics": "Grammar, Vocab, RC, Cloze Test",
      "completion": 0.80,
      "color": Colors.pink, // MaterialColor SWATCH
    },
    {
      "name": "Science",
      "description": "Physics, Chemistry, Biology, Environmental Science.",
      "subtopics": "Physics, Chemistry, Biology, Env.",
      "completion": 0.60,
      "color": Colors.blue, // MaterialColor SWATCH
    },
  ];

  List<Map<String, dynamic>> _foundTopics = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _foundTopics = _allTopics;
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allTopics;
    } else {
      results = _allTopics
          .where((topic) =>
          topic['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundTopics = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    // Define text colors that adapt to the theme for consistent look
    final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color placeholderColor = isDarkTheme? Colors.blue.shade300 : Colors.blue.shade800;
    final Color progressTrackColor = isDarkTheme? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);
    final Color progressValueColor = isDarkTheme? Colors.lightGreen.shade400 : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.examName} Topics"),
        // Colors are handled by MaterialApp's AppBarTheme
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- Search Bar ---
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              style: TextStyle(color: textColor), // Ensure text is visible in dark mode
              decoration: InputDecoration(
                labelText: 'Search for a topic',
                labelStyle: TextStyle(color: secondaryTextColor),
                suffixIcon: Icon(Icons.search, color: secondaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: secondaryTextColor),
                ),
                enabledBorder: OutlineInputBorder( // Define for enabled state
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder( // Define for focused state
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor), // Highlight with primary color
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- List of Topics ---
            Expanded(
              child: _foundTopics.isNotEmpty
                  ? ListView.builder(
                itemCount: _foundTopics.length,
                itemBuilder: (context, index) {
                  final topic = _foundTopics[index];
                  final String topicName = topic['name'];
                  final String description = topic['description'];
                  final String subtopics = topic['subtopics'];
                  final double completion = topic['completion'];

                  // Cast the stored color to MaterialColor to access shades
                  final MaterialColor topicMaterialColor = topic['color'] as MaterialColor;

                  // Adjust card color based on topic's base color and theme
                  final Color cardColor = isDarkTheme
                      ? topicMaterialColor.shade700
                      : topicMaterialColor.shade100;

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: cardColor, // Dynamic card color
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectScreen(
                              examName: widget.examName,
                              topicName: topicName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Topic Name ---
                            Text(
                              topicName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor, // Dynamic text color
                              ),
                            ),
                            const SizedBox(height: 4),
                            // --- Topic Description ---
                            Text(
                              description,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor), // Dynamic text color
                            ),
                            const SizedBox(height: 8),
                            // --- Subtopics ---
                            Text(
                              "Subtopics: $subtopics",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: secondaryTextColor.withOpacity(0.8)), // Dynamic text color
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
                                "Start learning this topic!",
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
              )
                  : Center(
                child: Text(
                  'No topics found. Try a different search term!',
                  style: TextStyle(fontSize: 16, color: textColor), // Dynamic text color
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}