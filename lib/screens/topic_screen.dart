import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import 'subject_screen.dart';

class TopicScreen extends StatefulWidget {
  final String examName;
  final List<String> examTopics; // NEW: Topics relevant to the selected exam
  final Map<String, List<String>> topicToSubjectsMap; // NEW: Passed from ExamScreen
  final Map<String, List<String>> subjectToSectionsMap; // NEW: Passed from ExamScreen

  const TopicScreen({
    super.key,
    required this.examName,
    required this.examTopics, // Required parameter
    required this.topicToSubjectsMap, // Required parameter
    required this.subjectToSectionsMap, // Required parameter
  });

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  // NEW: Removed hardcoded _allTopics. We will generate it from examTopics.
  List<Map<String, dynamic>> _allTopicsDisplayData = []; // This will hold data for display

  List<Map<String, dynamic>> _foundTopics = [];
  final TextEditingController _searchController = TextEditingController();

  // Placeholder for topic-specific descriptions and mock completion/colors
  // In a real app, this would be fetched from a database
  final Map<String, String> _topicDescriptions = {
    "Aptitude": "Numerical ability, data interpretation, logical reasoning.",
    "Reasoning": "Verbal and non-verbal reasoning, puzzles, series.",
    "GS": "History, Geography, Polity, Economy, Science & Tech.",
    "English": "Grammar, Vocabulary, Comprehension, Sentence Rearrangement.",
    "Science": "Physics, Chemistry, Biology, Environmental Science.",
  };

  final Map<String, MaterialColor> _topicDefaultColors = {
    "Aptitude": Colors.orange,
    "Reasoning": Colors.teal,
    "GS": Colors.green,
    "English": Colors.pink,
    "Science": Colors.blue,
  };

  @override
  void initState() {
    super.initState();
    _loadTopicsDisplayData(); // Load topics based on what's passed from ExamScreen
    _foundTopics = _allTopicsDisplayData;
  }

  void _loadTopicsDisplayData() {
    _allTopicsDisplayData = widget.examTopics.map((topicName) {
      return {
        "name": topicName,
        "description": _topicDescriptions[topicName]?? "$topicName related content.",
        "subtopics": widget.topicToSubjectsMap[topicName]?.join(', ')?? "No subtopics",
        "completion": 0.0 + (topicName.length % 5) * 0.1, // Mock completion
        "color": _topicDefaultColors[topicName]?? Colors.grey,
      };
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allTopicsDisplayData;
    } else {
      results = _allTopicsDisplayData
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

    final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color placeholderColor = isDarkTheme? Colors.blue.shade300 : Colors.blue.shade800;
    final Color progressTrackColor = isDarkTheme? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1);
    final Color progressValueColor = isDarkTheme? Colors.lightGreen.shade400 : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.examName} Topics"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Search for a topic',
                labelStyle: TextStyle(color: secondaryTextColor),
                suffixIcon: Icon(Icons.search, color: secondaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: secondaryTextColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: secondaryTextColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
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

                  final MaterialColor topicMaterialColor = topic['color'] as MaterialColor;

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
                    color: cardColor,
                    child: InkWell(
                      onTap: () {
                        // NEW: Pass subjects and maps to SubjectScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubjectScreen(
                              examName: widget.examName,
                              topicName: topicName,
                              topicToSubjectsMap: widget.topicToSubjectsMap, // Pass maps down
                              subjectToSectionsMap: widget.subjectToSectionsMap, // Pass maps down
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topicName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryTextColor),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Subtopics: $subtopics",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: secondaryTextColor.withOpacity(0.8)),
                            ),
                            const SizedBox(height: 16),

                            if (completion > 0)...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: completion,
                                  minHeight: 8,
                                  backgroundColor: progressTrackColor,
                                  valueColor: AlwaysStoppedAnimation<Color>(progressValueColor),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Completed: ${(completion * 100).toStringAsFixed(0)}%",
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor),
                              ),
                            ] else...[
                              Text(
                                "Start learning this topic!",
                                style: TextStyle(
                                    color: placeholderColor,
                                    fontWeight: FontWeight.w500),
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
                  style: TextStyle(fontSize: 16, color: textColor),
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