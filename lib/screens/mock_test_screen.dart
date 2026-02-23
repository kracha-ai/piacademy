// lib/screens/mock_test_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/theme_notifier.dart';
import 'result_screen.dart';
import '../models/question.dart';
import '../models/data_models.dart'; // <-- 1. IMPORT DATA MODELS

class MockTestScreen extends StatefulWidget {
  final String? exam;
  final String? topic;
  final String? subject;
  final Map<String, dynamic>? testData;
  final String? testFile;
  final String? language;

  // testId is now crucial for saving and resuming progress
  final String? testId;
  final String? testName;
  final int? durationMinutes;
  final List<Map<String, dynamic>> questions;

  const MockTestScreen({
    super.key,
    this.exam,
    this.topic,
    this.subject,
    this.testData,
    this.testFile,
    this.language,
    this.testId,
    this.testName,
    this.durationMinutes,
    required this.questions,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  // Your existing state variables
  List<Question> questions = [];
  List<Duration> questionTimes = [];
  bool showNavigator = false;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex; // This can be removed if not used elsewhere
  late String selectedLanguage;
  bool isLoading = true;

  late Timer _timer;
  final Stopwatch _totalStopwatch = Stopwatch();
  final Stopwatch _questionStopwatch = Stopwatch();
  Duration _currentQuestionElapsed = Duration.zero;
  Duration _totalElapsed = Duration.zero;
  int? _remainingSeconds;

  // --- 2. NEW AND MODIFIED STATE VARIABLES ---
  final DatabaseService _dbService = DatabaseService();
  // Using a Map for answers to align with our UnfinishedTest model
  Map<int, List<int>> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language?? 'en';
    // The main initialization logic is now wrapped in this single function
    _loadOrStartTest();
  }

  // --- 3. NEW: MAIN INITIALIZATION LOGIC ---
  Future<void> _loadOrStartTest() async {
    // A. First, load the question data into the 'questions' list from widgets
    _loadQuestionData();

    // B. Check the local DB for any saved progress for THIS specific test
    final savedProgress = await _dbService.getUnfinishedTest();

    // C. If we found progress AND it matches the current testId, RESUME the test
    if (savedProgress!= null && savedProgress.testId == widget.testId) {
      print("Resuming test '${widget.testName}'...");
      setState(() {
        currentQuestionIndex = savedProgress.currentQuestionIndex;
        _selectedAnswers = savedProgress.selectedAnswers;
        questionTimes = List.filled(questions.length, Duration.zero); // Reset question times for now

        if (widget.durationMinutes!= null) {
          _remainingSeconds = (widget.durationMinutes! * 60) - savedProgress.timeSpentSeconds;
          if (_remainingSeconds! < 0) _remainingSeconds = 0; // Failsafe
          _startCountdownTimer();
        } else {
          _totalElapsed = Duration(seconds: savedProgress.timeSpentSeconds);
          _startTestTimer();
        }
        isLoading = false;
      });
      _startQuestionTimer();
      _showSnackBar("Resuming test...", Colors.blue);
    }
    // D. Otherwise, START the test fresh
    else {
      print("Starting new test '${widget.testName}'...");
      setState(() {
        currentQuestionIndex = 0;
        _selectedAnswers = {}; // Start with empty answers
        questionTimes = List.filled(questions.length, Duration.zero);
        if (widget.durationMinutes!= null) {
          _remainingSeconds = widget.durationMinutes! * 60;
          _startCountdownTimer();
        } else {
          _startTestTimer();
        }
        isLoading = false;
      });
      _startQuestionTimer();
    }
  }

  // --- 4. NEW: Helper to consolidate your question loading logic ---
  void _loadQuestionData() {
    List<Map<String, dynamic>> sourceQuestions;

    if (widget.questions.isNotEmpty) {
      sourceQuestions = widget.questions;
    } else if (widget.testData!= null && widget.testData!['questions']!= null) {
      sourceQuestions = List<Map<String, dynamic>>.from(widget.testData!['questions']);
    } else if (widget.testFile!= null) {
      // This is a complex case. For now, we assume questions are passed via widget.questions or widget.testData
      // as your resume logic depends on a testId from Firestore.
      // If you need to resume local file tests, you would need a way to uniquely identify them.
      print("Loading from local test file. Resume functionality may not work without a unique testId.");
      // Your parsing logic would go here.
      return;
    } else {
      sourceQuestions = [];
    }

    questions = sourceQuestions.map((map) => Question.fromMap(map)).toList();
  }

  @override
  void dispose() {
    _timer.cancel();
    _totalStopwatch.stop();
    _questionStopwatch.stop();
    super.dispose();
  }

  // --- 5. NEW: SAVE PROGRESS ON EXIT ---
  /// This method is called when the user tries to leave the screen.
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Test?'),
        content: const Text('Your progress will be saved. Do you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _saveProgress(); // Call the save method
              Navigator.of(context).pop(true);
            },
            child: const Text('Save & Exit'),
          ),
        ],
      ),
    );
    return shouldPop?? false;
  }

  /// The actual logic to save the current test state to the local DB.
  Future<void> _saveProgress() async {
    if (widget.testId == null) {
      print("Cannot save progress: testId is null.");
      return;
    }

    _stopAndSaveQuestionTime();

    final int timeSpent = _remainingSeconds!= null
        ? (widget.durationMinutes! * 60) - _remainingSeconds!
        : _totalElapsed.inSeconds;

    final progress = UnfinishedTest(
      testId: widget.testId!,
      testName: widget.testName?? 'Unknown Test',
      currentQuestionIndex: currentQuestionIndex,
      selectedAnswers: _selectedAnswers,
      timeSpentSeconds: timeSpent,
    );

    await _dbService.saveUnfinishedTest(progress);
    _showSnackBar("Progress Saved!", Colors.orange);
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }

  // (Your existing timer, formatting, and old parsing logic can remain)
  // I am keeping them here for completeness.

  List<Question> parseQuestions(String rawData) {
    List<Question> questionList = [];
    List<String> blocks = rawData.split("Q_EN:");
    for (int i = 1; i < blocks.length; i++) {
      String block = "Q_EN:" + blocks[i];
      String qEn = extract(block, "Q_EN:");
      String qTe = extract(block, "Q_TE:");
      String askedIn = extract(block, "ASKED_IN:");
      List<String> optionsEn = [extract(block, "A_EN:"), extract(block, "B_EN:"), extract(block, "C_EN:"), extract(block, "D_EN:")];
      List<String> optionsTe = [extract(block, "A_TE:"), extract(block, "B_TE:"), extract(block, "C_TE:"), extract(block, "D_TE:")];
      String answerLetter = extract(block, "ANSWER:");
      int correctIndex = ["A", "B", "C", "D"].indexOf(answerLetter.trim());
      String category = extract(block, "CATEGORY:");
      String solEn = extract(block, "SOLUTION_EN:");
      String solTe = extract(block, "SOLUTION_TE:");

      questionList.add(Question(
          questionEn: qEn,
          questionTe: qTe,
          optionsEn: optionsEn,
          optionsTe: optionsTe,
          correctIndex: correctIndex,
          solutionEn: solEn,
          solutionTe: solTe,
          askedIn: askedIn,
          category: category.isNotEmpty? category : null
      ));
    }
    return questionList;
  }

  String extract(String text, String key) {
    RegExp reg = RegExp('$key(.*?)(?:\\n[A-Z_]+:|\\Z)', multiLine: true, dotAll: true);
    var match = reg.firstMatch(text);
    return match!= null? match.group(1)!.trim() : "";
  }

  void _startTestTimer() {
    _totalStopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _totalElapsed = _totalStopwatch.elapsed;
          _currentQuestionElapsed = _questionStopwatch.elapsed;
        });
      }
    });
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds! > 0) {
            _remainingSeconds = _remainingSeconds! - 1;
          } else {
            timer.cancel();
            _submitTest(autoSubmitted: true);
          }
          _currentQuestionElapsed = _questionStopwatch.elapsed;
        });
      }
    });
  }

  void _startQuestionTimer() {
    _questionStopwatch.reset();
    _questionStopwatch.start();
  }

  void _stopAndSaveQuestionTime() {
    _questionStopwatch.stop();
    if (currentQuestionIndex < questionTimes.length) {
      questionTimes[currentQuestionIndex] = _questionStopwatch.elapsed;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    String hours = twoDigits(duration.inHours);
    if (duration.inHours > 0) {
      return "$hours:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  String _formatSeconds(int totalSeconds) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(totalSeconds ~/ 60);
    final seconds = twoDigits(totalSeconds % 60);
    return "$minutes:$seconds";
  }

  String _formatQuestionDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  // --- 6. UPDATED SUBMIT TEST LOGIC ---
  void _submitTest({bool autoSubmitted = false}) async {
    _timer.cancel();
    _stopAndSaveQuestionTime();

    // NEW: Clear any saved progress from the local DB upon finishing the test.
    await _dbService.clearUnfinishedTest();

    score = 0;
    // Convert the map answers back to a list for the result screen
    final userAnswersList = List.generate(questions.length, (i) => _selectedAnswers[i]?.first);

    for (int i = 0; i < questions.length; i++) {
      if (userAnswersList[i]!= null && userAnswersList[i] == questions[i].correctIndex) {
        score++;
      }
    }

    final Duration totalTimeSpent = _remainingSeconds!= null
        ? Duration(seconds: (widget.durationMinutes! * 60) - _remainingSeconds!)
        : _totalElapsed;

    // Your existing logic to save the final result remains
    try {
      await _dbService.saveTestResult(
        testId: widget.testId?? widget.testFile?? 'unknown_test',
        testName: widget.testName?? widget.subject?? 'Test',
        score: score,
        totalQuestions: questions.length,
        timeTaken: totalTimeSpent,
        userAnswers: userAnswersList,
      );
    } catch (e) {
      print("UI Error saving test result: $e");
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          exam: widget.exam?? widget.testName?? 'Test',
          topic: widget.topic?? 'General',
          subject: widget.subject?? 'General',
          score: score,
          total: questions.length,
          questions: questions,
          userAnswers: userAnswersList,
          totalTime: totalTimeSpent,
          questionTimes: questionTimes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- 7. WRAP YOUR SCAFFOLD IN WillPopScope ---
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        // The rest of your UI code starts here...
        appBar: AppBar(
          title: Text(widget.testName?? "${widget.subject} Test"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  _remainingSeconds!= null? _formatSeconds(_remainingSeconds!) : _formatDuration(_totalElapsed),
                  style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedLanguage = selectedLanguage == "en"? "te" : "en";
                });
              },
              child: Text(
                selectedLanguage == "en"? "తెలుగు" : "English",
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        body: Builder(builder: (context) {
          // --- Moved UI rendering into a Builder to handle loading and empty states ---
          final themeNotifier = Provider.of<ThemeNotifier>(context);
          final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;
          final Color primaryTextColor = isDarkTheme? Colors.white : Colors.black87;

          if (isLoading) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }

          if (questions.isEmpty) {
            return Center(child: Text("No Questions Available.", style: TextStyle(color: primaryTextColor)));
          }

          final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
          final Color borderColor = isDarkTheme? Colors.grey.shade600 : Colors.grey.shade300;
          final Color selectedBorderColor = Theme.of(context).primaryColor;
          final Color answeredColor = isDarkTheme? Colors.green.shade700 : Colors.green;
          final Color currentQuestionColor = Theme.of(context).primaryColor;
          final Color unselectedAnswerColor = isDarkTheme? Colors.grey.shade800 : Colors.white;
          final Color navigatorPanelColor = isDarkTheme? Colors.grey.shade900 : Colors.white;

          final Question currentQuestionData = questions[currentQuestionIndex];
          final String qEn = currentQuestionData.questionEn;
          final String qTe = currentQuestionData.questionTe;
          final List optionsEn = currentQuestionData.optionsEn;
          final List optionsTe = currentQuestionData.optionsTe;
          final String askedIn = currentQuestionData.askedIn;
          final String? category = currentQuestionData.category;

          const double navigatorPanelWidth = 250.0;
          const double toggleButtonTopPosition = 550.0;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Question ${currentQuestionIndex + 1} of ${questions.length}",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                        ),
                        Text(
                          "Q-Time: ${_formatQuestionDuration(_currentQuestionElapsed)}",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      selectedLanguage == "en"? qEn : qTe,
                      style: TextStyle(fontSize: 18, color: primaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    if (askedIn.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDarkTheme? Colors.blueGrey.shade700 : Colors.blueGrey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Asked in: $askedIn",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkTheme? Colors.white : Colors.black87),
                        ),
                      ),
                    if (category!= null && category.trim().isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isDarkTheme? Colors.teal.shade700 : Colors.teal.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Category: $category",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkTheme? Colors.white : Colors.black87),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: optionsEn.length,
                        itemBuilder: (context, index) {
                          List<String> labels = ["A", "B", "C", "D"];
                          // --- 8. UI UPDATE ---
                          bool isSelected = (_selectedAnswers[currentQuestionIndex]?.firstOrNull == index);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                // --- 8. UI UPDATE ---
                                _selectedAnswers[currentQuestionIndex] = [index];
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isSelected? selectedBorderColor.withOpacity(0.1) : unselectedAnswerColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected? selectedBorderColor : borderColor,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${labels[index]}. ",
                                    style: TextStyle(fontWeight: isSelected? FontWeight.bold : FontWeight.normal, fontSize: 16, color: primaryTextColor),
                                  ),
                                  Expanded(
                                    child: Text(
                                      selectedLanguage == "en"? optionsEn[index] : optionsTe[index],
                                      style: TextStyle(fontSize: 16, fontWeight: isSelected? FontWeight.bold : FontWeight.normal, color: primaryTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isDarkTheme? Colors.grey.shade700 : Colors.grey.shade400, foregroundColor: primaryTextColor),
                          onPressed: currentQuestionIndex == 0? null : () {
                            setState(() {
                              _stopAndSaveQuestionTime();
                              currentQuestionIndex--;
                              _startQuestionTimer();
                            });
                          },
                          child: const Text("Previous"),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text("Submit"),
                          onPressed: () => _submitTest(autoSubmitted: false),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                          onPressed: () {
                            if (currentQuestionIndex < questions.length - 1) {
                              setState(() {
                                _stopAndSaveQuestionTime();
                                currentQuestionIndex++;
                                _startQuestionTimer();
                              });
                            } else {
                              _submitTest(autoSubmitted: false);
                            }
                          },
                          child: Text(currentQuestionIndex == questions.length - 1? "Finish" : "Next"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: showNavigator? 0 : -navigatorPanelWidth,
                top: 0,
                bottom: 0,
                width: navigatorPanelWidth,
                child: Container(
                  color: navigatorPanelColor,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      // --- 8. UI UPDATE ---
                      bool isAnswered = _selectedAnswers.containsKey(index);
                      bool isCurrent = currentQuestionIndex == index;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _stopAndSaveQuestionTime();
                            currentQuestionIndex = index;
                            showNavigator = false;
                            _startQuestionTimer();
                          });
                        },
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent? currentQuestionColor : isAnswered? answeredColor : isDarkTheme? Colors.grey.shade800 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "${index + 1}",
                            style: TextStyle(fontWeight: FontWeight.bold, color: (isCurrent || isAnswered)? Colors.white : primaryTextColor),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: toggleButtonTopPosition,
                left: 0,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      showNavigator =!showNavigator;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
                    ),
                    child: Icon(showNavigator? Icons.arrow_back_ios : Icons.arrow_forward_ios, color: Theme.of(context).appBarTheme.foregroundColor, size: 18),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// --- What Your Mock Test Screen Does ---
//
// 1. Flexible Data Loading: It can load questions from multiple sources:
// - Direct Data (`widget.questions`): From a pre-fetched list (e.g., from Firestore).
// - Firestore Map (`widget.testData`): From a single test document map.
// - Local Asset File (`widget.testFile`): From a text file bundled with the app.
//
// 2. State Management: It manages the entire state of a test session, including
// the current question, user's answers, and time spent on each question.
//
// 3. Advanced Timer Logic: It supports both countdown and count-up timers,
// automatically submitting the test when a countdown finishes.
//
// 4. Interactive UI: It provides a rich user interface with:
// - Bilingual question and option display (English/Telugu).
// - A slide-out "Question Navigator" panel for quick jumping.
// - Visual feedback for selected answers and answered questions.
//
// 5. Test Submission: Upon completion, it calculates the score, saves the final
// result using your DatabaseService, and navigates to a `ResultScreen`.