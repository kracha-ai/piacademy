import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 1. AppColors Class Definition
class AppColors {
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color accent = Color(0xFFE11D48);
  static const Color easy = Color(0xFF10B981);
  static const Color medium = Color(0xFFF59E0B);
  static const Color hard = Color(0xFFEF4444);
}

// Enum to match the one in CreateTestScreen
enum TestType {
  sectionWise,
  fullSubject,
  fullMock,
}

// 2. The Main Widget
class ViewTestsScreen extends StatefulWidget {
  const ViewTestsScreen({super.key});

  @override
  State<ViewTestsScreen> createState() => _ViewTestsScreenState();
}

class _ViewTestsScreenState extends State<ViewTestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  // --- Filter state variables ---
  String? exam;
  String? topic;
  String? subject;
  String? section;
  String? difficulty;
  TestType? testType;
  DateTime? startDate;
  int _currentCount = 0;

  // --- Options for dependent dropdowns ---
  List<String> subjectOptions = [];
  List<String> sectionOptions = [];

  // --- The COMPREHENSIVE "Rulebook" for the hierarchy (from your ExamScreen) ---
  // These maps MUST be present in this class for the dropdowns to work.
  // If you update this in the Android app, remember to copy these exact maps
  // to your web admin panel to maintain consistency.

  // Store _allExamsData directly here for filtering
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

  // Derived options for dropdowns
  List<String> _getExamNames() => _allExamsData.map((e) => e['name'] as String).toList();
  List<String> _getTopicOptionsForSelectedExam() {
    if (exam == null) return _comprehensiveTopicToSubjectsMap.keys.toList(); // All topics if no exam selected
    final selectedExamData = _allExamsData.firstWhere(
          (e) => e['name'] == exam,
      orElse: () => {"topics": <String>[]},
    );
    // FIX: Corrected type casting to avoid syntax error
    // It should be `as List<dynamic>?` and then `?? []`
    return List<String>.from(
      (selectedExamData['topics'] as List<dynamic>?) ?? [],
    );
  }

  final List<String> difficultyOptions = ['Easy', 'Medium', 'Hard']; // Difficulty is still global

  void _onExamChanged(String? newExam) {
    setState(() {
      exam = newExam;
      topic = null; // Reset topic when exam changes
      subject = null; // Reset subject
      section = null; // Reset section
      subjectOptions = []; // Reset subject options
      sectionOptions = []; // Reset section options
    });
  }

  void _onTopicChanged(String? newTopic) {
    setState(() {
      topic = newTopic;
      subject = null;
      section = null;
      subjectOptions = newTopic!= null? _comprehensiveTopicToSubjectsMap[newTopic]! : [];
      sectionOptions = [];
    });
  }

  void _onSubjectChanged(String? newSubject) {
    setState(() {
      subject = newSubject;
      section = null;
      sectionOptions = newSubject!= null? _comprehensiveSubjectToSectionsMap[newSubject]?? [] : [];
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      exam = null;
      topic = null;
      subject = null;
      section = null;
      difficulty = null;
      testType = null;
      startDate = null;
      subjectOptions = [];
      sectionOptions = [];
    });
  }

  // NEW: Method to handle editing a question (kept as is)
  Future<void> _editQuestion(String testId, int questionIndex, Map<String, dynamic> initialQuestionData) async {
    final Map<String, dynamic>? updatedQuestion = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuestionScreen(
          initialQuestionData: initialQuestionData,
        ),
      ),
    );

    if (updatedQuestion!= null) {
      final DocumentReference testRef = FirebaseFirestore.instance.collection('tests').doc(testId);
      final DocumentSnapshot testDoc = await testRef.get();

      if (testDoc.exists) {
        final Map<String, dynamic> currentTestData = testDoc.data() as Map<String, dynamic>;
        // Create a modifiable list from the Firestore list
        final List<dynamic> questions = List.from(currentTestData['questions']?? []);

        if (questionIndex >= 0 && questionIndex < questions.length) {
          questions[questionIndex] = updatedQuestion; // Update the specific question
          await testRef.update({
            'questions': questions,
            'updatedAt': FieldValue.serverTimestamp(), // Optional: add an update timestamp
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Question index out of bounds.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Test document not found.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('tests').orderBy('createdAt', descending: true);

    if (exam!= null) query = query.where('exam', isEqualTo: exam);
    if (difficulty!= null) query = query.where('difficulty', isEqualTo: difficulty);
    if (startDate!= null) query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);
    if (testType!= null) query = query.where('testType', isEqualTo: testType!.name);

    if (testType!= TestType.fullMock) {
      if (topic!= null) query = query.where('topic', isEqualTo: topic);
      if (subject!= null) query = query.where('subject', isEqualTo: subject);
      if (testType == TestType.sectionWise && section!= null) {
        query = query.where('section', isEqualTo: section);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: BoxDecoration(color: AppColors.surface, border: Border(right: BorderSide(color: AppColors.border))),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Library", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Row(children: [
                      const Icon(Icons.analytics_outlined, size: 18, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text("$_currentCount Tests Found", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(hintText: "Search name...", prefixIcon: const Icon(Icons.search, size: 20), filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 40),
                  const Text("FILTERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),

                  _sidebarDropdownEnum<TestType>(
                    "Test Type",
                    testType,
                    TestType.values,
                        (val) => setState(() => testType = val),
                        (type) => type.name.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (match) => ' ${match.group(0)}').replaceFirstMapped(RegExp(r'^\w'), (match) => match.group(0)!.toUpperCase()),
                  ),

                  // NEW: Use _getExamNames() for exam options
                  _sidebarDropdown("Exam", exam, _getExamNames(), _onExamChanged),
                  if (testType!= TestType.fullMock)...[
                    // NEW: Use _getTopicOptionsForSelectedExam() for topic options
                    _sidebarDropdown("Topic", topic, _getTopicOptionsForSelectedExam(), _onTopicChanged),
                    if (topic!= null)
                      _sidebarDropdown("Subject", subject, subjectOptions, _onSubjectChanged),
                    if (testType == TestType.sectionWise && subject!= null && sectionOptions.isNotEmpty)
                      _sidebarDropdown("Section", section, sectionOptions, (val) => setState(() => section = val)),
                  ],

                  _sidebarDropdown("Difficulty", difficulty, difficultyOptions, (val) => setState(() => difficulty = val)),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Created After", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(startDate == null? "Select Date" : DateFormat('dd MMM yyyy').format(startDate!)),
                    trailing: const Icon(Icons.calendar_month, size: 20),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime.now());
                      if (picked!= null) setState(() => startDate = picked);
                    },
                  ),
                  const SizedBox(height: 20),
                  if (exam!= null || topic!= null || subject!= null || section!= null || difficulty!= null || testType!= null || startDate!= null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _resetFilters,
                        child: const Text("Reset All Filters", style: TextStyle(color: AppColors.accent)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) {
                  print("FULL FIRESTORE ERROR: ${snapshot.error}");
                  return Center(child: Text("An error occurred: ${snapshot.error}"));
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                if (_searchController.text.isNotEmpty) {
                  final s = _searchController.text.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name']?? '').toLowerCase().contains(s);
                  }).toList();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _currentCount!= docs.length) setState(() => _currentCount = docs.length);
                });

                if (docs.isEmpty) return const Center(child: Text("No tests found matching your criteria."));

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String currentTestId = docs[index].id;
                    return _ExpandableTestTile(
                      testId: currentTestId,
                      data: data,
                      onDelete: () => _confirmDelete(currentTestId, data['name']?? 'test'),
                      onEditQuestion: _editQuestion,
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // --- UPDATED WIDGET: Builds dropdowns with an "All" option ---
  Widget _sidebarDropdown(String label, String? selected, List<String> values, Function(String?) onSelected) {
    // Create a new list of items that includes the "All" option at the top
    List<DropdownMenuItem<String>> items = [
      DropdownMenuItem(
        value: null, // Selecting this will set the filter to null
        child: Text("All $label", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
      ),
      ...values.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected == null? AppColors.background : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected == null? AppColors.border : AppColors.primaryBlue),
            ),
            child: DropdownButton<String>(
              value: selected,
              hint: Text("All $label", style: const TextStyle(fontSize: 14)),
              isExpanded: true,
              underline: const SizedBox(),
              items: items,
              onChanged: onSelected,
            ),
          ),
        ],
      ),
    );
  }

  // --- UPDATED WIDGET: Builds Enum dropdowns with an "All" option ---
  Widget _sidebarDropdownEnum<T>(String label, T? selected, List<T> values, Function(T?) onSelected, String Function(T) display) {
    // Create a new list of items that includes the "All" option
    List<DropdownMenuItem<T>> items = [
      DropdownMenuItem(
        value: null, // This represents the "All" option
        child: Text("All $label", style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
      ),
      ...values.map((e) => DropdownMenuItem(value: e, child: Text(display(e), style: const TextStyle(fontSize: 14)))),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected == null? AppColors.background : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected == null? AppColors.border : AppColors.primaryBlue),
            ),
            child: DropdownButton<T>(
              value: selected,
              hint: Text("All $label", style: const TextStyle(fontSize: 14)),
              isExpanded: true,
              underline: const SizedBox(),
              items: items,
              onChanged: onSelected,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String id, String name) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Test?"),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.hard, foregroundColor: Colors.white), child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('tests').doc(id).delete();
    }
  }
}

class _ExpandableTestTile extends StatelessWidget {
  final String testId;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  final Function(String testId, int questionIndex, Map<String, dynamic> initialQuestionData) onEditQuestion;

  const _ExpandableTestTile({
    required this.testId,
    required this.data,
    required this.onDelete,
    required this.onEditQuestion,
  });

  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.secondaryText),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.secondaryText)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List questions = data['questions']?? [];

    final String testTypeString = data['testType']?.replaceAllMapped(RegExp(r'(?<=[a-z])[A-Z]'), (match) => ' ${match.group(0)}')?? 'N/A';
    final String formattedTestType = testTypeString.replaceFirstMapped(RegExp(r'^\w'), (m) => m.group(0)!.toUpperCase());
    final timestamp = data['createdAt'] as Timestamp?;
    final String date = timestamp!= null? DateFormat('MMM d, yyyy').format(timestamp.toDate()) : 'N/A';
    final String testType = data['testType']?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: AppColors.border,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        title: Text(
          data['name']?? 'Untitled',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            children: [
              _buildInfoChip(data['exam']?? 'N/A', Icons.school),
              _buildInfoChip(formattedTestType, Icons.rule),
              if (testType!= 'fullMock')
                _buildInfoChip(data['topic']?? 'N/A', Icons.topic),
              if (testType!= 'fullMock')
                _buildInfoChip(data['subject']?? 'N/A', Icons.book),
              _buildInfoChip(data['difficulty']?? 'N/A', Icons.speed),
              _buildInfoChip("${questions.length} Qs", Icons.help_outline),
              _buildInfoChip(date, Icons.calendar_today),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.hard),
          onPressed: onDelete,
          tooltip: "Delete Test",
        ),
        children: <Widget>[
          const Divider(height: 1, thickness: 1),
          Container(
            color: Colors.black.withOpacity(0.02),
            child: Column(
              children: [
                for (int i = 0; i < questions.length; i++)
                  _QuestionExpansionTile(
                    questionData: questions[i],
                    index: i,
                    testId: testId,
                    onEditQuestion: onEditQuestion,
                  ),
                if (questions.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text("This test has no questions."))),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _QuestionExpansionTile extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final int index;
  final String testId;
  final Function(String testId, int questionIndex, Map<String, dynamic> initialQuestionData) onEditQuestion;

  const _QuestionExpansionTile({
    required this.questionData,
    required this.index,
    required this.testId,
    required this.onEditQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final int correctIndex = questionData['correctAnswerIndex']?? -1;
    final List optionsEn = questionData['options_en']?? [];

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
        child: Text(
          '${index + 1}',
          style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
      title: Text(questionData['text_en']?? 'No question text', style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primaryBlue, size: 20),
            onPressed: () => onEditQuestion(testId, index, questionData),
            tooltip: "Edit Question",
          ),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          alignment: Alignment.topLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (questionData['text_te']!= null && questionData['text_te'].isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 12),
                  child: Text(questionData['text_te'], style: const TextStyle(fontSize: 16, color: AppColors.secondaryText)),
                ),
              const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
              const SizedBox(height: 8),
              for (int i = 0; i < optionsEn.length; i++)
                ListTile(
                  dense: true,
                  leading: Icon(
                    i == correctIndex? Icons.check_circle : Icons.radio_button_unchecked,
                    color: i == correctIndex? AppColors.easy : AppColors.secondaryText.withOpacity(0.5),
                    size: 20,
                  ),
                  title: Text(
                    optionsEn[i],
                    style: TextStyle(
                      fontWeight: i == correctIndex? FontWeight.bold : FontWeight.normal,
                      color: i == correctIndex? AppColors.easy : AppColors.primaryText,
                    ),
                  ),
                ),
              if (questionData['solution_en']!= null || questionData['solution_te']!= null)...[
                const Divider(height: 24),
                const Text("Solution:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
                const SizedBox(height: 8),
                if (questionData['solution_en']!= null)
                  Text(
                    "EN: ${questionData['solution_en']}",
                    style: const TextStyle(color: AppColors.primaryText, fontStyle: FontStyle.italic),
                  ),
                if (questionData['solution_te']!= null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "TE: ${questionData['solution_te']}",
                      style: const TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic),
                    ),
                  ),
              ]
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionDetailView extends StatelessWidget {
  final Map<String, dynamic> questionData;
  final int index;

  const _QuestionDetailView({required this.questionData, required this.index});

  @override
  Widget build(BuildContext context) {
    final int correctIndex = questionData['correctAnswerIndex']?? -1;
    final List optionsEn = questionData['options_en']?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${index + 1}. ${questionData['text_en']?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText)),
          if (questionData['text_te']!= null)
            Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(questionData['text_te'], style: const TextStyle(fontSize: 16, color: AppColors.secondaryText))),
          const Divider(height: 24),
          const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 8),
          for (int i = 0; i < optionsEn.length; i++)
            ListTile(
              dense: true,
              leading: Icon(i == correctIndex? Icons.check_circle : Icons.radio_button_unchecked, color: i == correctIndex? AppColors.easy : AppColors.secondaryText.withOpacity(0.5), size: 20),
              title: Text(optionsEn[i], style: TextStyle(fontWeight: i == correctIndex? FontWeight.bold : FontWeight.normal, color: i == correctIndex? AppColors.easy : AppColors.primaryText)),
            ),
          if (questionData['solution_en']!= null || questionData['solution_te']!= null)...[
            const Divider(height: 24),
            const Text("Solution:", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
            const SizedBox(height: 8),
            if (questionData['solution_en']!= null)
              Text("EN: ${questionData['solution_en']}", style: const TextStyle(color: AppColors.primaryText, fontStyle: FontStyle.italic)),
            if (questionData['solution_te']!= null)
              Padding(padding: const EdgeInsets.only(top: 4.0), child: Text("TE: ${questionData['solution_te']}", style: const TextStyle(color: AppColors.secondaryText, fontStyle: FontStyle.italic))),
          ]
        ],
      ),
    );
  }
}

class _CompactTestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _CompactTestCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color diffColor = AppColors.medium;
    if (data['difficulty'] == 'Easy') diffColor = AppColors.easy;
    if (data['difficulty'] == 'Hard') diffColor = AppColors.hard;

    String subtitle;
    if (data['testType'] == 'fullMock') {
      subtitle = data['exam']?? 'Full Mock';
    } else if (data['testType'] == 'fullSubject') {
      subtitle = data['subject']?? 'Full Subject';
    } else {
      subtitle = data['section']?? data['subject']?? 'General';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((data['difficulty']?? '').toUpperCase(), style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.bold)),
              InkWell(onTap: onDelete, child: Icon(Icons.delete_outline, color: AppColors.hard, size: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Text(data['name']?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          Text(subtitle, maxLines: 1, style: const TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.help_outline, size: 12, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text("${(data['questions'] as List?)?.length?? 0} Q", style: const TextStyle(fontSize: 10)),
              const Spacer(),
              Icon(Icons.timer_outlined, size: 12, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text("${data['durationMinutes']?? 0}m", style: const TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}

class EditQuestionScreen extends StatefulWidget {
  final Map<String, dynamic> initialQuestionData;

  const EditQuestionScreen({super.key, required this.initialQuestionData});

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  late TextEditingController _questionTextEnController;
  late TextEditingController _questionTextTeController;
  late TextEditingController _solutionEnController;
  late TextEditingController _solutionTeController;

  List<TextEditingController> _optionEnControllers = [];
  List<TextEditingController> _optionTeControllers = [];
  int _correctAnswerIndex = -1;

  @override
  void initState() {
    super.initState();
    _questionTextEnController = TextEditingController(text: widget.initialQuestionData['text_en']);
    _questionTextTeController = TextEditingController(text: widget.initialQuestionData['text_te']);
    _solutionEnController = TextEditingController(text: widget.initialQuestionData['solution_en']);
    _solutionTeController = TextEditingController(text: widget.initialQuestionData['solution_te']);

    _correctAnswerIndex = widget.initialQuestionData['correctAnswerIndex']?? -1;

    List<dynamic> initialOptionsEn = widget.initialQuestionData['options_en']?? [];
    for (String option in initialOptionsEn.cast<String>()) {
      _optionEnControllers.add(TextEditingController(text: option));
    }
    while (_optionEnControllers.length < 4) {
      _optionEnControllers.add(TextEditingController());
    }

    List<dynamic> initialOptionsTe = widget.initialQuestionData['options_te']?? [];
    for (String option in initialOptionsTe.cast<String>()) {
      _optionTeControllers.add(TextEditingController(text: option));
    }
    while (_optionTeControllers.length < 4) {
      _optionTeControllers.add(TextEditingController());
    }
    int maxOptions = (_optionEnControllers.length > _optionTeControllers.length)? _optionEnControllers.length : _optionTeControllers.length;
    while (_optionEnControllers.length < maxOptions) {
      _optionEnControllers.add(TextEditingController());
    }
    while (_optionTeControllers.length < maxOptions) {
      _optionTeControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _questionTextEnController.dispose();
    _questionTextTeController.dispose();
    _solutionEnController.dispose();
    _solutionTeController.dispose();
    for (var controller in _optionEnControllers) {
      controller.dispose();
    }
    for (var controller in _optionTeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    if (_questionTextEnController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question text (English) cannot be empty.')),
      );
      return;
    }
    if (_optionEnControllers.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All English options must have text.')),
      );
      return;
    }
    if (_questionTextTeController.text.trim().isNotEmpty && _optionTeControllers.any((controller) => controller.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('If Telugu question text is provided, all Telugu options must also have text.')),
      );
      return;
    }

    if (_correctAnswerIndex == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a correct answer.')),
      );
      return;
    }

    Map<String, dynamic> updatedQuestion = {
      ...widget.initialQuestionData,
      'text_en': _questionTextEnController.text.trim(),
      'text_te': _questionTextTeController.text.trim(),
      'solution_en': _solutionEnController.text.trim(),
      'solution_te': _solutionTeController.text.trim(),
      'options_en': _optionEnControllers.map((c) => c.text.trim()).toList(),
      'options_te': _optionTeControllers.map((c) => c.text.trim()).toList(),
      'correctAnswerIndex': _correctAnswerIndex,
    };
    Navigator.pop(context, updatedQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Question"),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Question Text (English)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _questionTextEnController,
              decoration: InputDecoration(
                hintText: "Enter question in English",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.background,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),

            Text("Question Text (Telugu - Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _questionTextTeController,
              decoration: InputDecoration(
                hintText: "Enter question in Telugu (optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.background,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 24),

            const Text("Options:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryText)),
            const SizedBox(height: 12),
            for (int i = 0; i < _optionEnControllers.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _correctAnswerIndex,
                      onChanged: (int? value) {
                        setState(() {
                          _correctAnswerIndex = value!;
                        });
                      },
                      activeColor: AppColors.easy,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Option ${i + 1} (English)", style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                          TextField(
                            controller: _optionEnControllers[i],
                            decoration: InputDecoration(
                              hintText: "Enter option ${i + 1} in English",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: AppColors.background,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text("Option ${i + 1} (Telugu)", style: TextStyle(fontSize: 12, color: AppColors.secondaryText)),
                          TextField(
                            controller: _optionTeControllers[i],
                            decoration: InputDecoration(
                              hintText: "Enter option ${i + 1} in Telugu (optional)",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              filled: true,
                              fillColor: AppColors.background,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            Text("Solution (English - Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _solutionEnController,
              decoration: InputDecoration(
                hintText: "Enter solution in English (optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.background,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),

            Text("Solution (Telugu - Optional)", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText)),
            const SizedBox(height: 8),
            TextField(
              controller: _solutionTeController,
              decoration: InputDecoration(
                hintText: "Enter solution in Telugu (optional)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.background,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Save Changes", style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}