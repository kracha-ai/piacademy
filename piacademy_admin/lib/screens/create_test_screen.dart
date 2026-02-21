import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/question_form_dialog.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

// --- NEW: An Enum to clearly define the different types of tests you can create ---
enum TestType {
  sectionWise,
  fullSubject,
  fullMock,
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _totalQuestionsController = TextEditingController();

  // --- NEW: State variable for the main Test Type selector ---
  TestType _selectedTestType = TestType.sectionWise;

  // --- State variables for the 4-level hierarchy ---
  late String _selectedExam;
  late String _selectedTopic;
  late String _selectedSubject;
  late String _selectedSection;
  late String _selectedDifficulty;

  late List<String> _subjectOptions;
  late List<String> _sectionOptions;

  bool _isFeatured = false;
  // --- NEW: State for the topic grouping switch. Default is ON. ---
  bool _groupPerTopic = true;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _questions = [];

  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color bgGrey = Color(0xFFF8F9FA);

  // --- The "Rulebook" for your hierarchy ---
  // Level 1
  final List<String> examOptions = ['RRB', 'SSC', 'UPSC', 'Bank'];

  // Level 2
  final List<String> topicOptions = ['Aptitude', 'Reasoning', 'Science', 'GS', 'English'];
  final List<String> difficultyOptions = ['Easy', 'Medium', 'Hard'];

  // Level 3: Maps a Topic to its list of Subjects
  final Map<String, List<String>> topicToSubjectsMap = {
    'Aptitude': ['Number System', 'Arithmetic', 'Time & Speed/Work', 'Algebra', 'Geometry & Mensuration', 'Data Interpretation (DI)', 'Modern Math'],
    'Reasoning': ['Verbal Reasoning', 'Analytical/Logical Reasoning', 'Non-Verbal & Spatial Reasoning', 'Puzzles & Arrangements'],
    'Science': ['Physics', 'Chemistry', 'Biology', 'Technology/Misc'],
    'GS': ['Indian History', 'Geography', 'Indian Polity', 'Economy', 'Current Affairs', 'Static GK'],
    'English': ['Reading Comprehension', 'Grammar', 'Vocabulary', 'Sentence Structure']
  };

  // Level 4: Maps a Subject to its list of Sections
  final Map<String, List<String>> subjectToSectionsMap = {
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

  @override
  void initState() {
    super.initState();
    // Initialize the state with default values to prevent errors
    _selectedExam = examOptions.first;
    _selectedTopic = topicOptions.first;
    _selectedDifficulty = difficultyOptions[1]; // Medium

    // Set the initial lists for the dependent dropdowns
    _subjectOptions = topicToSubjectsMap[_selectedTopic]!;
    _selectedSubject = _subjectOptions.first;

    _sectionOptions = subjectToSectionsMap[_selectedSubject]?? [];
    _selectedSection = _sectionOptions.isNotEmpty? _sectionOptions.first : '';
  }

  void _onTopicChanged(String newTopic) {
    setState(() {
      _selectedTopic = newTopic;

      _subjectOptions = topicToSubjectsMap[_selectedTopic]!;
      _selectedSubject = _subjectOptions.first;

      _sectionOptions = subjectToSectionsMap[_selectedSubject]?? [];
      _selectedSection = _sectionOptions.isNotEmpty? _sectionOptions.first : '';
    });
  }

  void _onSubjectChanged(String newSubject) {
    setState(() {
      _selectedSubject = newSubject;

      _sectionOptions = subjectToSectionsMap[_selectedSubject]?? [];
      _selectedSection = _sectionOptions.isNotEmpty? _sectionOptions.first : '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _sectionBox("General Settings", [
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputStyle("Test Title", Icons.edit),
                      validator: (v) => v!.isEmpty? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: _inputStyle("Description", Icons.description),
                      maxLines: 2,
                      validator: (v) => v!.isEmpty? "Required" : null,
                    ),
                  ]),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _sectionBox("Configuration", [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _durationController,
                            keyboardType: TextInputType.number,
                            decoration: _inputStyle("Mins", Icons.timer),
                            validator: (v) => v!.isEmpty? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _totalQuestionsController,
                            // --- FIX #1: Changed TextInput to TextInputType ---
                            keyboardType: TextInputType.number,
                            decoration: _inputStyle("Qty", Icons.numbers),
                            validator: (v) => v!.isEmpty? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildDropdown("Difficulty", _selectedDifficulty, difficultyOptions, (v) => setState(() => _selectedDifficulty = v!)),
                    const SizedBox(height: 15),
                    SwitchListTile(
                      title: Text('Feature on Home Screen', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                      value: _isFeatured,
                      onChanged: (val) => setState(() => _isFeatured = val),
                      activeColor: primaryBlue,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _sectionBox("Test Type", [
              DropdownButtonFormField<TestType>(
                value: _selectedTestType,
                decoration: _inputStyle("Select the type of test", Icons.rule),
                items: const [
                  DropdownMenuItem(value: TestType.sectionWise, child: Text("Section-wise Test (Specific)")),
                  DropdownMenuItem(value: TestType.fullSubject, child: Text("Full Subject Test")),
                  DropdownMenuItem(value: TestType.fullMock, child: Text("Full Mock Test (Entire Exam)")),
                ],
                onChanged: (TestType? newValue) {
                  setState(() {
                    _selectedTestType = newValue!;
                  });
                },
              ),
              if (_selectedTestType == TestType.fullMock)...[
                const SizedBox(height: 15),
                SwitchListTile(
                  title: Text('Group questions by Topic', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: Text('If ON, user sees all Aptitude, then all Reasoning, etc. If OFF, all questions are mixed.', style: GoogleFonts.inter(fontSize: 12)),
                  value: _groupPerTopic,
                  onChanged: (val) => setState(() => _groupPerTopic = val),
                  activeColor: primaryBlue,
                  contentPadding: EdgeInsets.zero,
                ),
              ]
            ]),
            const SizedBox(height: 32),
            _sectionBox("Test Hierarchy", [
              _buildDropdown("Exam", _selectedExam, examOptions, (v) => setState(() => _selectedExam = v!)),
              if (_selectedTestType!= TestType.fullMock)...[
                const SizedBox(height: 15),
                _buildDropdown("Topic", _selectedTopic, topicOptions, (v) => _onTopicChanged(v!)),
              ],
              if (_selectedTestType!= TestType.fullMock)...[
                const SizedBox(height: 15),
                _buildDropdown("Subject", _selectedSubject, _subjectOptions, (v) => _onSubjectChanged(v!)),
              ],
              if (_selectedTestType == TestType.sectionWise && _sectionOptions.isNotEmpty)...[
                const SizedBox(height: 15),
                _buildDropdown("Section", _selectedSection, _sectionOptions, (v) => setState(() => _selectedSection = v!)),
              ],
            ]),
            const SizedBox(height: 32),
            _sectionBox("Questions Management", [
              Row(
                children: [
                  _actionBtn("Bulk Import (.txt)", Icons.upload_file, _pickAndProcessFile),
                  const SizedBox(width: 12),
                  _actionBtn("Manual Question", Icons.add_circle, _addQuestionManually),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading? null : _uploadTest,
                  icon: _isLoading? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.cloud_upload),
                  label: Text("UPLOAD ENTIRE TEST TO SERVER", style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 32),
            _sectionBox("Draft Questions (${_questions.length})", [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  final int correctIdx = (q['correctAnswerIndex']?? 0).toInt();
                  final String topicLabel = q['topic']!= null? "Topic: ${q['topic']} | " : "";
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: bgGrey,
                    elevation: 0,
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: primaryBlue.withOpacity(0.1), child: Text((index + 1).toString(), style: const TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold))),
                      title: Text(q['text_en']?? '', style: const TextStyle(fontSize: 14)),
                      // --- FIX #2: Correctly combined the string variables ---
                      subtitle: Text("${topicLabel}Answer: ${String.fromCharCode(65 + correctIdx)}", style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _questions.removeAt(index)),
                      ),
                    ),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // --- UI HELPERS ---
  Widget _sectionBox(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: primaryBlue)),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          side: const BorderSide(color: primaryBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18, color: primaryBlue),
      filled: true,
      fillColor: bgGrey,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    final isValueValid = items.contains(value);
    return DropdownButtonFormField<String>(
      value: isValueValid? value : null,
      decoration: _inputStyle(label, Icons.layers),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
      hint: items.isEmpty? const Text("Not applicable", style: TextStyle(fontSize: 13)) : null,
    );
  }

  // --- LOGIC METHODS ---
  Future<void> _addQuestionManually() async {
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(context: context, builder: (context) => const QuestionFormDialog());
    if (result!= null) {
      setState(() {
        if (_selectedTestType!= TestType.fullMock) {
          result['topic'] = _selectedTopic;
        }
        _questions.add(result);
      });
    }
  }

  Future<void> _pickAndProcessFile() async {
    setState(() => _isLoading = true);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['txt'], withData: true);
      if (result!= null && result.files.single.bytes!= null) {
        final content = utf8.decode(result.files.single.bytes!);
        final lines = content.split('\n');
        List<Map<String, dynamic>> parsed = [];
        Map<String, dynamic> current = {'type': 'MCQ'};
        List<String> optEn = List.filled(4, '');
        List<String> optTe = List.filled(4, '');
        String? answer;
        String? currentTopic;
        void saveCurrent() {
          if (current.containsKey('text_en') && answer!= null) {
            int idx = ['A', 'B', 'C', 'D'].indexOf(answer!.trim().toUpperCase());
            if (idx!= -1) {
              current['options_en'] = List.from(optEn);
              current['options_te'] = List.from(optTe);
              current['correctAnswerIndex'] = idx;
              if (currentTopic!= null) {
                current['topic'] = currentTopic;
              }
              parsed.add(current);
            }
          }
          current = {'type': 'MCQ'};
          optEn = List.filled(4, '');
          optTe = List.filled(4, '');
          answer = null;
        }
        for (String line in lines) {
          String trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          if (trimmed.startsWith('TOPIC:')) {
            currentTopic = trimmed.substring(6).trim();
            continue;
          }
          if (trimmed.startsWith('Q_EN:') && current.containsKey('text_en')) {
            saveCurrent();
          }
          if (trimmed.contains(':')) {
            final parts = trimmed.split(':');
            final key = parts[0].trim();
            final value = parts.sublist(1).join(':').trim();
            switch (key) {
              case 'Q_EN': current['text_en'] = value; break;
              case 'Q_TE': current['text_te'] = value; break;
              case 'A_EN': optEn[0] = value; break;
              case 'B_EN': optEn[1] = value; break;
              case 'C_EN': optEn[2] = value; break;
              case 'D_EN': optEn[3] = value; break;
              case 'A_TE': optTe[0] = value; break;
              case 'B_TE': optTe[1] = value; break;
              case 'C_EN': optTe[2] = value; break;
              case 'D_TE': optTe[3] = value; break;
              case 'ANSWER': answer = value; break;
              case 'SOLUTION_EN': current['solution_en'] = value; break;
              case 'SOLUTION_TE': current['solution_te'] = value; break;
            }
          }
        }
        saveCurrent();
        setState(() => _questions.addAll(parsed));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${parsed.length} questions imported successfully!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error processing file: $e"), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _uploadTest() async {
    if (!_formKey.currentState!.validate() || _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Check your settings and add questions!"), backgroundColor: Colors.orange));
      return;
    }
    setState(() => _isLoading = true);

    Map<String, dynamic> testData = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'durationMinutes': int.parse(_durationController.text),
      'totalQuestions': int.parse(_totalQuestionsController.text),
      'difficulty': _selectedDifficulty,
      'isFeatured': _isFeatured,
      'createdAt': FieldValue.serverTimestamp(),
      'questions': _questions,
      'testType': _selectedTestType.name,
    };

    switch (_selectedTestType) {
      case TestType.sectionWise:
        if (_sectionOptions.isNotEmpty && _selectedSection.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a section."), backgroundColor: Colors.orange));
          setState(() => _isLoading = false);
          return;
        }
        testData['exam'] = _selectedExam;
        testData['topic'] = _selectedTopic;
        testData['subject'] = _selectedSubject;
        testData['section'] = _sectionOptions.isNotEmpty? _selectedSection : 'General';
        break;
      case TestType.fullSubject:
        testData['exam'] = _selectedExam;
        testData['topic'] = _selectedTopic;
        testData['subject'] = _selectedSubject;
        testData['section'] = 'Full Subject';
        break;
      case TestType.fullMock:
        testData['exam'] = _selectedExam;
        testData['topic'] = 'Full Mock';
        testData['subject'] = 'Full Mock';
        testData['section'] = 'Full Mock';
        testData['groupPerTopic'] = _groupPerTopic;
        break;
    }

    try {
      await FirebaseFirestore.instance.collection('tests').add(testData);

      _nameController.clear();
      _descriptionController.clear();
      _durationController.clear();
      _totalQuestionsController.clear();
      setState(() {
        _questions.clear();
        _isFeatured = false;
        _groupPerTopic = true;
        _selectedTestType = TestType.sectionWise;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test Uploaded Successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e"), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }
}