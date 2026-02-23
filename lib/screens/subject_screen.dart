import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import 'test_list_screen.dart';

class SubjectScreen extends StatefulWidget {
  final String examName;
  final String topicName;
  final Map<String, List<String>> topicToSubjectsMap;
  final Map<String, List<String>> subjectToSectionsMap;

  const SubjectScreen({
    super.key,
    required this.examName,
    required this.topicName,
    required this.topicToSubjectsMap,
    required this.subjectToSectionsMap,
  });

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  List<Map<String, dynamic>> _allSubjects = [];

  // Placeholder for subject-specific descriptions and mock completion/colors
  final Map<String, String> _subjectDescriptions = {
    'Number System': "Focus on properties of numbers and basic operations.",
    'Arithmetic': "Concepts of percentages, profit/loss, interest, and ratios.",
    'Time & Speed/Work': "Problems involving time, speed, distance, work, and pipes.",
    'Algebra': "Linear/quadratic equations, polynomials, and mathematical expressions.",
    'Geometry & Mensuration': "Shapes, areas, volumes, and properties of geometric figures.",
    'Data Interpretation (DI)': "Analysis of data presented in graphs, charts, and tables.",
    'Modern Math': "Probability, permutations, combinations, and sequences.",
    'Verbal Reasoning': "Analogies, coding-decoding, blood relations, and direction sense.",
    'Analytical/Logical Reasoning': "Syllogisms, statements-conclusions, arguments, and data sufficiency.",
    'Non-Verbal & Spatial Reasoning': "Mirror images, embedded figures, pattern completion.",
    'Puzzles & Arrangements': "Seating arrangements, matrix puzzles, and scheduling.",
    'Physics': "Fundamental laws of nature, mechanics, electricity.",
    'Chemistry': "Composition, structure, properties, and reactions of matter.",
    'Biology': "Study of life, organisms, evolution, and ecosystems.",
    'Technology/Misc': "Space, defense, renewable energy, and nuclear technologies.",
    'Indian History': "Study of ancient, medieval, and modern Indian history.",
    'Geography': "Physical, human, and economic geography of India and the World.",
    'Indian Polity': "Indian Constitution, governance, and public administration.",
    'Economy': "Indian economy basics, banking, budget, and taxation.",
    'Current Affairs': "National and international news, government schemes, awards.",
    'Static GK': "Important dates, books, authors, capitals, and organizations.",
    'Reading Comprehension': "Understanding passages, inference, and tone.",
    'Grammar': "Error detection, sentence improvement, subject-verb agreement.",
    'Vocabulary': "Synonyms, antonyms, idioms, phrases, and one-word substitutions.",
    'Sentence Structure': "Sentence rearrangement, cloze tests, and fill in the blanks.",
  };

  // FIX: Changed value type from MaterialColor to Color
  final Map<String, Color> _subjectDefaultColors = {
    'Number System': Colors.blue,
    'Arithmetic': Colors.green,
    'Time & Speed/Work': Colors.orange,
    'Algebra': Colors.purple,
    'Geometry & Mensuration': Colors.teal,
    'Data Interpretation (DI)': Colors.red,
    'Modern Math': Colors.indigo,
    'Verbal Reasoning': Colors.cyan,
    'Analytical/Logical Reasoning': Colors.deepOrange,
    'Non-Verbal & Spatial Reasoning': Colors.pink,
    'Puzzles & Arrangements': Colors.brown,
    'Physics': Colors.lime,
    'Chemistry': Colors.amber,
    'Biology': Colors.lightGreen,
    'Technology/Misc': Colors.blueGrey,
    'Indian History': Colors.deepPurple,
    'Geography': Colors.lightBlue,
    'Indian Polity': Colors.deepOrangeAccent, // Now correctly assigned
    'Economy': Colors.tealAccent, // Now correctly assigned
    'Current Affairs': Colors.redAccent, // Now correctly assigned
    'Static GK': Colors.greenAccent, // Now correctly assigned
    'Reading Comprehension': Colors.blueAccent, // Now correctly assigned
    'Grammar': Colors.purpleAccent, // Now correctly assigned
    'Vocabulary': Colors.orangeAccent, // Now correctly assigned
    'Sentence Structure': Colors.cyanAccent,
  };

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    final List<String>? subjectsForCurrentTopic = widget.topicToSubjectsMap[widget.topicName];

    if (subjectsForCurrentTopic!= null) {
      _allSubjects = subjectsForCurrentTopic.map((subjectName) {
        return {
          "name": subjectName,
          "description": _subjectDescriptions[subjectName]?? "$subjectName content for ${widget.examName} ${widget.topicName}.",
          "completion": 0.0 + (subjectName.length % 5) * 0.1, // Mock completion
          "color": _subjectDefaultColors[subjectName]?? Colors.grey, // Assign default color or fallback
        };
      }).toList();
    } else {
      _allSubjects = [];
    }
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
        title: Text("${widget.examName} - ${widget.topicName}"),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allSubjects.length,
        itemBuilder: (context, index) {
          final subject = _allSubjects[index];
          final String subjectName = subject['name'];
          final String description = subject['description'];
          final double completion = subject['completion'];

          final dynamic subjectBaseColor = subject['color']; // Keep as dynamic for now

          Color cardColor;
          // Check if it's an AccentColor or a regular MaterialColor to pick the right shade
          if (subjectBaseColor is MaterialAccentColor) {
            cardColor = isDarkTheme? subjectBaseColor.shade400 : subjectBaseColor.shade100;
          } else if (subjectBaseColor is MaterialColor) {
            cardColor = isDarkTheme? subjectBaseColor.shade700 : subjectBaseColor.shade100;
          } else {
            // Fallback for any other unexpected Color type, or simple Color
            cardColor = isDarkTheme? Colors.grey.shade700 : Colors.grey.shade100;
          }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TestListScreen(
                      exam: widget.examName,
                      topic: widget.topicName,
                      subject: subjectName,
                      subjectToSectionsMap: widget.subjectToSectionsMap,
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
                      subjectName,
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
                        "Start exploring this subject!",
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
      ),
    );
  }
}