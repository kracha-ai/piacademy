import 'package:flutter/material.dart';
import 'topic_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  // NEW: All comprehensive rulebook data for the hierarchy
  // This will ensure consistency across Exam, Topic, and Subject screens.
  final List<Map<String, dynamic>> _allExamsData = [
    {
      "name": "RRB",
      "description": "15 Full Tests, 50+ Practice Sets",
      "avgScore": 0.75, // Represents 75%
      "color": Colors.red, // MaterialColor
      "topics": ['Aptitude', 'Reasoning', 'GS', 'Science'], // Topics specific to RRB
    },
    {
      "name": "SSC",
      "description": "25 Full Tests, 120+ Practice Sets",
      "avgScore": 0.68, // Represents 68%
      "color": Colors.purple, // MaterialColor
      "topics": ['Aptitude', 'Reasoning', 'GS', 'English', 'Science'], // Topics specific to SSC
    },
    {
      "name": "UPSC",
      "description": "10 Full Tests, 80+ Practice Sets",
      "avgScore": 0.82, // Represents 82%
      "color": Colors.green, // MaterialColor
      "topics": ['GS', 'English'], // Topics specific to UPSC
    },
    {
      "name": "Bank",
      "description": "30 Full Tests, 200+ Practice Sets",
      "avgScore": 0.0, // Represents 0% (not started)
      "color": Colors.blue, // MaterialColor
      "topics": ['Aptitude', 'Reasoning', 'English'], // Topics specific to Bank
    }
  ];

  final Map<String, List<String>> _comprehensiveTopicToSubjectsMap = {
    'Aptitude': ['Number System', 'Arithmetic', 'Time & Speed/Work', 'Algebra', 'Geometry & Mensuration', 'Data Interpretation (DI)', 'Modern Math'],
    'Reasoning': ['Verbal Reasoning', 'Analytical/Logical Reasoning', 'Non-Verbal & Spatial Reasoning', 'Puzzles & Arrangements'],
    'Science': ['Physics', 'Chemistry', 'Biology', 'Technology/Misc'],
    'GS': ['Indian History', 'Geography', 'Indian Polity', 'Economy', 'Current Affairs', 'Static GK'],
    'English': ['Reading Comprehension', 'Grammar', 'Vocabulary', 'Sentence Structure']
  };

  final Map<String, List<String>> _comprehensiveSubjectToSectionsMap = {
    'Number System': ['Divisibility rules', 'HCF & LCM', 'Prime Numbers', 'Fractions/Decimals'],
    'Arithmetic': ['Percentages', 'Profit & Loss', 'Discount', 'Simple & Compound Interest', 'Average', 'Ratio & Proportion', 'Mixture & Alligation', 'Partnerships', 'Ages'],
    'Time & Speed/Work': ['Time and Work', 'Pipes & Cisterns', 'Time, Speed & Distance', 'Boats & Streams', 'Problems on Trains'],
    'Algebra': ['Linear & Quadratic Equations', 'Polynomials', 'Surds & Indices', 'Logarithms'],
    'Geometry & Mensuration': ['Triangles', 'Circles', 'Polygons', 'Area & Perimeter (2D)', 'Volume & Surface Area (3D)', 'Co-ordinate Geometry'],
    'Data Interpretation (DI)': ['Bar Graphs', 'Pie Charts', 'Line Graphs', 'Tables', 'Data Sufficiency'],
    'Modern Math': ['Probability', 'Permutations & Combinations', 'Sequence & Series (AP/GP/HP)'],
    'Verbal Reasoning': ['Analogy', 'Classification (Odd One Out)', 'Coding-Decoding', 'Blood Relations', 'Direction Sense', 'Series (Number/Alphabet)', 'Ranking'],
    'Analytical/Logical Reasoning': ['Syllogism', 'Statements & Conclusions', 'Assumptions', 'Arguments', 'Cause & Effect', 'Course of Action', 'Data Sufficiency'],
    'Non-Verbal & Spatial Reasoning': ['Mirror/Water Images', 'Embedded Figures', 'Pattern Completion', 'Paper Folding/Cutting', 'Dice & Cube Problems'],
    'Puzzles & Arrangements': ['Seating Arrangement (Linear/Circular)', 'Matrix Puzzle', 'Scheduling/Data-based Puzzles'],
    'Physics': ['Units & Measurements', 'Mechanics', 'Work, Power & Energy', 'Gravitation', 'Light & Optics', 'Sound', 'Electricity & Magnetism', 'Heat & Thermodynamics'],
    'Chemistry': ['Atomic Structure', 'Chemical Bonding', 'Acids, Bases & Salts', 'Metals & Non-metals', 'Periodic Table', 'Environmental Chemistry', 'Everyday Chemistry'],
    'Biology': ['Cell Structure & Functions', 'Classification of Organisms', 'Human Anatomy & Physiology', 'Nutrition & Food', 'Health & Diseases'],
    'Technology/Misc': ['Space Technology', 'Defense Tech', 'Renewable Energy', 'Nuclear Technology'],
    'Indian History': ['Ancient', 'Medieval', 'Modern History'],
    'Geography': ['Physical', 'Indian', 'World Geography'],
    'Indian Polity': ['Constitution of India', 'Fundamental Rights', 'Parliament', 'Judiciary', 'Panchayati Raj'],
    'Economy': ['Basics of Indian Economy', 'Banking System', 'Budget', 'Taxation', 'GDP', 'Inflation'],
    'Current Affairs': ['National & International News', 'Government Schemes', 'Sports', 'Awards & Honors', 'Appointments'],
    'Static GK': ['Important Dates', 'Books & Authors', 'Capitals & Currencies', 'Organizations'],
    'Reading Comprehension': ['Passage Theme', 'Inference', 'Tone', 'Vocabulary'],
    'Grammar': ['Error Detection', 'Sentence Improvement', 'Subject-Verb Agreement', 'Tenses', 'Articles', 'Prepositions', 'Active/Passive Voice', 'Direct/Indirect Speech'],
    'Vocabulary': ['Synonyms & Antonyms', 'Idioms & Phrases', 'One Word Substitution', 'Spellings'],
    'Sentence Structure': ['Sentence Rearrangement (Para Jumbles)', 'Cloze Test', 'Fill in the Blanks']
  };

  // This list will hold the exams that are currently visible (for search).
  List<Map<String, dynamic>> _foundExams = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _foundExams = _allExamsData; // Use the comprehensive data
    super.initState();
  }

  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allExamsData; // Filter on comprehensive data
    } else {
      results = _allExamsData
          .where((exam) =>
          exam['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundExams = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Exam"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                labelText: 'Search for an exam',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _foundExams.isNotEmpty
                  ? ListView.builder(
                itemCount: _foundExams.length,
                itemBuilder: (context, index) {
                  final exam = _foundExams[index];
                  final String examName = exam['name'];
                  final String description = exam['description'];
                  final double avgScore = exam['avgScore'];
                  final Color color = exam['color']; // Assumed to be MaterialColor directly

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () {
                        // NEW: Pass comprehensive data to TopicScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicScreen(
                              examName: examName,
                              examTopics: exam['topics'] as List<String>, // Pass topics for this exam
                              topicToSubjectsMap: _comprehensiveTopicToSubjectsMap,
                              subjectToSectionsMap: _comprehensiveSubjectToSectionsMap,
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
                              examName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),
                            if (avgScore > 0)...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: avgScore,
                                  minHeight: 8,
                                  backgroundColor: Colors.black.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Average Score: ${(avgScore * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              )
                            ] else...[
                              Text(
                                "You haven't tried this yet. Start practicing!",
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : const Center(
                child: Text(
                  'No exams found. Try a different search term!',
                  style: TextStyle(fontSize: 16),
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