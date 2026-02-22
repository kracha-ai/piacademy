// lib/screens/mock_test_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart'; // Make sure to import this
import '../services/theme_notifier.dart';
import 'result_screen.dart';
import '../models/question.dart';

class MockTestScreen extends StatefulWidget {
  // --- UPGRADE 1: All parameters are now optional ---
  final String? exam;
  final String? topic;
  final String? subject;
  final Map<String, dynamic>? testData; // Changed from String? to Map?
  final String? testFile;               // Added this back for the local file path
  final String? language;

  // --- UPGRADE 2: New optional parameters are added ---
  final String? testId;
  final String? testName;
  final int? durationMinutes;
  final List? questions;

  const MockTestScreen({
    super.key,
    this.exam,
    this.topic,
    this.subject,
    this.testData,
    this.testFile, // Added this
    this.language,
    this.testId,
    this.testName,
    this.durationMinutes,
    this.questions,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  // Your original state variables are all preserved
  List<dynamic> questions = [];
  List<int?> userAnswers = [];
  List<Duration> questionTimes = [];
  bool showNavigator = false;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  late String selectedLanguage;
  bool isLoading = true;

  late Timer _timer;
  final Stopwatch _totalStopwatch = Stopwatch();
  final Stopwatch _questionStopwatch = Stopwatch();
  Duration _currentQuestionElapsed = Duration.zero;
  Duration _totalElapsed = Duration.zero;
  int? _remainingSeconds; // For the new countdown timer path

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language?? 'en';

    // --- UPGRADE 3: The simple logic check ---
    if (widget.questions != null && widget.questions!.isNotEmpty) {
      _initializeFromDirectData();
    } else if (widget.testData != null) {
      // NEW PATH: Handle the Firestore Map passed from TestListScreen
      _initializeFromFirestoreData();
    } else {
      loadQuestions();
    }
  }

  // --- NEW FUNCTION: To handle data passed directly from HomeScreen ---
  void _initializeFromDirectData() {
    setState(() {
      questions = widget.questions!;
      userAnswers = List.filled(questions.length, null);
      questionTimes = List.filled(questions.length, Duration.zero);
      // Set the countdown timer if duration is provided
      if (widget.durationMinutes!= null) {
        _remainingSeconds = widget.durationMinutes! * 60;
      }
      isLoading = false;
    });

    _startCountdownTimer(); // Use the countdown timer for this path
    _startQuestionTimer();
  }

  void _initializeFromFirestoreData() {
    setState(() {
      questions = widget.testData!['questions'] ?? [];
      userAnswers = List.filled(questions.length, null);
      questionTimes = List.filled(questions.length, Duration.zero);

      // Automatically set the timer based on Admin upload
      if (widget.testData!['durationMinutes'] != null) {
        _remainingSeconds = (widget.testData!['durationMinutes'] as int) * 60;
      }
      isLoading = false;
    });

    if (_remainingSeconds != null) {
      _startCountdownTimer();
    } else {
      _startTestTimer();
    }
    _startQuestionTimer();
  }

  // YOUR ORIGINAL FUNCTIONS ARE ALL PRESERVED
  @override
  void dispose() {
    _timer.cancel();
    _totalStopwatch.stop();
    _questionStopwatch.stop();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    if (widget.testFile == null) {
      setState(() => isLoading = false); return;
    }
    try {
      final data = await rootBundle.loadString(widget.testFile!);
      List<Question> loadedQuestions = parseQuestions(data);
      setState(() {
        questions = loadedQuestions;
        userAnswers = List.filled(questions.length, null);
        questionTimes = List.filled(questions.length, Duration.zero);
        isLoading = false;
      });
      _startTestTimer(); // Original stopwatch timer
      _startQuestionTimer();
    } catch (e) {
      print("Error loading questions: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

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
      String solEn = extract(block, "SOLUTION_EN:");
      String solTe = extract(block, "SOLUTION_TE:");
      questionList.add(Question(questionEn: qEn, questionTe: qTe, optionsEn: optionsEn, optionsTe: optionsTe, correctIndex: correctIndex, solutionEn: solEn, solutionTe: solTe, askedIn: askedIn));
    }
    return questionList;
  }

  String extract(String text, String key) {
    RegExp reg = RegExp('$key(.*)');
    var match = reg.firstMatch(text);
    return match!= null? match.group(1)!.trim() : "";
  }

  // Your original stopwatch timer
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

  // The new countdown timer
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
    if(currentQuestionIndex < questionTimes.length) {
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

  // --- UPGRADED _submitTest FUNCTION ---
  void _submitTest({bool autoSubmitted = false}) async {
    _timer.cancel();
    _stopAndSaveQuestionTime();

    score = 0;
    List<Question> resultQuestions = [];
    for (int i = 0; i < questions.length; i++) {
      final questionData = questions[i];
      final bool isFirestoreData = questionData is Map;
      final int correctIndex = isFirestoreData? (questionData['correctAnswerIndex']?? -1) : (questionData as Question).correctIndex;
      if (userAnswers[i]!= null && userAnswers[i] == correctIndex) {
        score++;
      }
      if (isFirestoreData) {
        resultQuestions.add(Question(
            questionEn: questionData['text_en']?? '',
            questionTe: questionData['text_te']?? '',
            optionsEn: List<String>.from(questionData['options_en']?? []),
            optionsTe: List<String>.from(questionData['options_te']?? []),
            correctIndex: correctIndex,
            solutionEn: questionData['solution_en']?? '',
            solutionTe: questionData['solution_te']?? '',
            askedIn: ''));
      } else {
        resultQuestions.add(questionData as Question);
      }
    }

    final Duration totalTimeSpent = _remainingSeconds!= null
        ? Duration(seconds: (widget.durationMinutes! * 60) - _remainingSeconds!)
        : _totalElapsed;

    // Call the database service
    final DatabaseService dbService = DatabaseService();
    try {
      await dbService.saveTestResult(
        testId: widget.testId?? widget.testFile?? 'unknown_test',
        testName: widget.testName?? widget.subject?? 'Test',
        score: score,
        totalQuestions: questions.length,
        timeTaken: totalTimeSpent,
        userAnswers: userAnswers,
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
          questions: resultQuestions,
          userAnswers: userAnswers,
          totalTime: totalTimeSpent,
          questionTimes: questionTimes,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // YOUR ENTIRE ORIGINAL BUILD METHOD IS HERE, WITH TWO SMALL CHANGES
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    final Color primaryTextColor = isDarkTheme? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color borderColor = isDarkTheme? Colors.grey.shade600 : Colors.grey.shade300;
    final Color selectedBorderColor = Theme.of(context).primaryColor;
    final Color answeredColor = isDarkTheme? Colors.green.shade700 : Colors.green;
    final Color currentQuestionColor = Theme.of(context).primaryColor;
    final Color unselectedAnswerColor = isDarkTheme? Colors.grey.shade800 : Colors.white;
    final Color navigatorPanelColor = isDarkTheme? Colors.grey.shade900 : Colors.white;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mock Test")),
        body: Center(child: Text("No Questions Available.", style: TextStyle(color: primaryTextColor))),
      );
    }

    final currentQuestionData = questions[currentQuestionIndex];
    final bool isFirestoreData = currentQuestionData is Map;

    final String qEn = isFirestoreData? (currentQuestionData['text_en']?? '') : (currentQuestionData as Question).questionEn;
    final String qTe = isFirestoreData? (currentQuestionData['text_te']?? '') : (currentQuestionData as Question).questionTe;
    final List optionsEn = isFirestoreData? (currentQuestionData['options_en']?? []) : (currentQuestionData as Question).optionsEn;
    final List optionsTe = isFirestoreData? (currentQuestionData['options_te']?? []) : (currentQuestionData as Question).optionsTe;
    final String askedIn = isFirestoreData? '' : (currentQuestionData as Question).askedIn;

    const double navigatorPanelWidth = 250.0;
    const double toggleButtonTopPosition = 550.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.testName?? "${widget.subject} Test"), // Smart title
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                // Smart timer display
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
      body: Stack(
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
                    decoration: BoxDecoration(
                      color: isDarkTheme? Colors.yellow.shade700 : Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Asked in: $askedIn",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkTheme? Colors.white : Colors.black87),
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: optionsEn.length,
                    itemBuilder: (context, index) {
                      List<String> labels = ["A", "B", "C", "D"];
                      bool isSelected = (userAnswers[currentQuestionIndex] == index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            userAnswers[currentQuestionIndex] = index;
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
                  bool isAnswered = userAnswers[index]!= null;
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
      ),
    );
  }
}