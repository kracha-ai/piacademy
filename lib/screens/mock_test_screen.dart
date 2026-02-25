// lib/screens/mock_test_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../services/theme_notifier.dart';
import 'result_screen.dart';
import '../models/question.dart';
import '../models/data_models.dart';

class MockTestScreen extends StatefulWidget {
  final String? exam;
  final String? topic;
  final String? subject;
  final Map<String, dynamic>? testData;
  final String? testFile;
  final String? language;

  // These are the crucial fields for identifying and loading the test from Firestore/resume
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
    required this.questions, // This should contain the actual question data
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  List<Question> questions = [];
  List<Duration> questionTimes = []; // Store time spent per question
  bool showNavigator = false;
  int currentQuestionIndex = 0;
  int score = 0;
  late String selectedLanguage;
  bool isLoading = true;

  late Timer _timer; // Main test timer (countdown or count-up)
  final Stopwatch _totalStopwatch = Stopwatch(); // For count-up timer if no duration limit
  final Stopwatch _questionStopwatch = Stopwatch(); // For current question timer

  // --- FIX 1: Declared as state variables ---
  Duration _currentQuestionElapsed = Duration.zero; // Time elapsed for the current question
  Duration _totalElapsed = Duration.zero; // Total elapsed time for the test (for display)
  // --- END FIX 1 ---

  Duration _totalTimeSpentActual = Duration.zero; // For accurate time calculation when disposing

  int? _remainingSeconds; // For countdown timer display
  int? _initialDurationSeconds; // Store initial duration for calculation

  final DatabaseService _dbService = DatabaseService();
  Map<int, List<int>> _selectedAnswers = {}; // {questionIndex: [selectedOptionIndex]}
  Set<int> _markedForReview = {}; // Set of question indices marked for review

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language?? 'en';
    _loadQuestionData(); // Load questions first

    // Initialize questionTimes with zero duration for each question
    questionTimes = List.generate(questions.length, (index) => Duration.zero);

    _pageController = PageController(initialPage: currentQuestionIndex);
    _loadOrStartTest(); // Then load existing progress or start new
  }

  Future<void> _loadOrStartTest() async {
    final savedProgress = await _dbService.getUnfinishedTest();

    // Determine the unique test identifier for the current test being launched
    // Use widget.testId if available (for Firestore-backed tests), otherwise fallback to other unique identifiers
    final String currentLaunchedTestId = widget.testId?? widget.testFile?? "${widget.exam?? ''}_${widget.topic?? ''}_${widget.subject?? ''}";

    // Check if there's saved progress AND if it's for the CURRENT test being launched
    if (savedProgress!= null && savedProgress.testId == currentLaunchedTestId) {
      print("MockTestScreen: Resuming test '${widget.testName}' (ID: ${savedProgress.testId})...");
      setState(() {
        currentQuestionIndex = savedProgress.currentQuestionIndex;
        _selectedAnswers = savedProgress.selectedAnswers;
        _markedForReview = savedProgress.markedForReviewQuestions?.toSet()?? {};
        // Restore questionTimes (if saved, otherwise use savedProgress.timeSpentSeconds for _totalTimeSpentActual)
        // For now, we only save _totalTimeSpentActual, not individual questionTimes
        _totalTimeSpentActual = Duration(seconds: savedProgress.timeSpentSeconds);

        _initialDurationSeconds = widget.durationMinutes!= null? (widget.durationMinutes! * 60) : null;

        if (_initialDurationSeconds!= null) {
          // If it's a countdown test
          _remainingSeconds = _initialDurationSeconds! - savedProgress.timeSpentSeconds;
          if (_remainingSeconds! < 0) _remainingSeconds = 0; // Ensure remaining time is not negative
          _startCountdownTimer();
        } else {
          // If it's a count-up test
          _totalStopwatch.start();
          // _totalStopwatch.elapsedMicroseconds; // Initialize stopwatch elapsed time
          // This line is not needed, _totalStopwatch.elapsed will start from zero,
          // and _totalElapsed will correctly add _totalTimeSpentActual.
          _startTestTimer(); // Starts the timer for total elapsed time
        }
        isLoading = false;
      });
      // Jump to the saved question, but only if the PageController is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(currentQuestionIndex);
        }
      });
      _startQuestionTimer(resume: true); // Start timer for current question
      _showSnackBar("Resuming test '${widget.testName}'...", Colors.blue);
    } else {
      // If no saved progress, or saved progress is for a different test, start a new test
      print("MockTestScreen: Starting new test '${widget.testName}' (ID: $currentLaunchedTestId)...");
      // If there was an unfinished test for a *different* ID, clear it
      if (savedProgress!= null && savedProgress.testId!= currentLaunchedTestId) {
        await _dbService.clearUnfinishedTest();
        print("MockTestScreen: Cleared old unfinished test (ID: ${savedProgress.testId}) from local DB as it was for a different test.");
      }

      setState(() {
        currentQuestionIndex = 0;
        _selectedAnswers = {};
        _markedForReview = {};
        _totalTimeSpentActual = Duration.zero; // Reset actual time spent
        _initialDurationSeconds = widget.durationMinutes!= null? (widget.durationMinutes! * 60) : null;

        if (_initialDurationSeconds!= null) {
          _remainingSeconds = _initialDurationSeconds;
          _startCountdownTimer();
        } else {
          _totalStopwatch.start();
          _startTestTimer(); // Starts the timer for total elapsed time
        }
        isLoading = false;
      });
      _startQuestionTimer(); // Start timer for current question
    }
  }

  void _loadQuestionData() {
    List<Map<String, dynamic>> sourceQuestions;

    if (widget.questions.isNotEmpty) {
      // Questions explicitly passed, use them
      sourceQuestions = widget.questions;
    } else if (widget.testData!= null && widget.testData!['questions']!= null) {
      // Questions within testData (e.g., from Firestore)
      sourceQuestions = List<Map<String, dynamic>>.from(widget.testData!['questions']);
    } else if (widget.testFile!= null) {
      // Assuming testFile implies questions are loaded via parseQuestions from a local asset
      // For now, this path doesn't automatically load questions here as it needs a Future<String> load,
      // which is outside the scope of initState. You'd need to manage this as a FutureBuilder or similar.
      // For simplicity, we'll proceed with an empty list if this is the only path.
      print("MockTestScreen: Loading from local test file specified by testFile. Ensure questions are loaded elsewhere or pass via 'questions'.");
      sourceQuestions = []; // Will result in "No Questions Available" if not loaded elsewhere
    } else {
      sourceQuestions = []; // Default to empty if no source
    }
    questions = sourceQuestions.map((map) => Question.fromMap(map)).toList();
    // Re-initialize questionTimes list to match the new questions length
    questionTimes = List.generate(questions.length, (index) => Duration.zero);
  }

  @override
  void dispose() {
    // Make sure to cancel timers and stop stopwatches before disposing
    _timer.cancel();
    _totalStopwatch.stop();
    _questionStopwatch.stop();
    _pageController.dispose();

    // IMPORTANT: Save progress when disposing the screen
    // This handles scenarios where the user exits via back button, home button, app killed, etc.
    _saveProgress();

    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // This is now handled by PopScope's onPopInvoked directly
    return false; // Prevent default pop behavior as onPopInvoked handles it
  }

  Future<void> _saveProgress() async {
    // Determine the unique test identifier for the current test
    final String testIdentifier = widget.testId?? widget.testFile?? "${widget.exam?? ''}_${widget.topic?? ''}_${widget.subject?? ''}";

    if (questions.isEmpty || testIdentifier.isEmpty) {
      print("MockTestScreen: Cannot save progress. Questions are empty or test identifier is null/empty.");
      return;
    }

    // Save time for the question the user is currently on before saving global progress
    _saveCurrentQuestionTime();

    // Calculate total time spent based on timer type
    final int timeSpentSeconds = _initialDurationSeconds!= null // If it's a countdown
        ? (_initialDurationSeconds! - (_remainingSeconds?? 0)) // Initial duration minus remaining
        : (_totalStopwatch.elapsed + _totalTimeSpentActual).inSeconds; // If it's a count-up, use stopwatch elapsed + previously spent time

    final progress = UnfinishedTest(
      testId: testIdentifier,
      testName: widget.testName?? 'Unknown Test',
      currentQuestionIndex: currentQuestionIndex,
      selectedAnswers: _selectedAnswers, // Save all selected answers (Map<int, List<int>>)
      timeSpentSeconds: timeSpentSeconds,
      markedForReviewQuestions: _markedForReview.toList(), // Save marked questions as a list
    );

    await _dbService.saveUnfinishedTest(progress);
    _showSnackBar("Progress Saved!", Colors.orange);
    print("MockTestScreen: Progress saved for ${progress.testName}, Q:${progress.currentQuestionIndex + 1}, Time:${progress.timeSpentSeconds}s");
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
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
          _totalElapsed = _totalStopwatch.elapsed + _totalTimeSpentActual; // Add any previously elapsed time
          _currentQuestionElapsed = questionTimes[currentQuestionIndex] + _questionStopwatch.elapsed;
        });
      }
    });
  }

  void _startCountdownTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds!= null && _remainingSeconds! > 0) {
            _remainingSeconds = _remainingSeconds! - 1;
            _totalTimeSpentActual = Duration(seconds: _totalTimeSpentActual.inSeconds + 1); // Increment actual time spent
          } else {
            timer.cancel();
            _confirmAndSubmitTest(autoSubmitted: true);
          }
          _currentQuestionElapsed = questionTimes[currentQuestionIndex] + _questionStopwatch.elapsed;
        });
      }
    });
  }

  void _startQuestionTimer({bool resume = false}) {
    _questionStopwatch.stop(); // Stop previous question timer
    _questionStopwatch.reset(); // Reset for new question

    if (resume && currentQuestionIndex < questionTimes.length) {
      // If resuming and there's saved time for this question, set it
      _currentQuestionElapsed = questionTimes[currentQuestionIndex];
    } else {
      _currentQuestionElapsed = Duration.zero; // Start from zero for new question
    }
    _questionStopwatch.start();
  }

  void _saveCurrentQuestionTime() {
    // Only save if stopwatches are running and current question is valid
    if (_questionStopwatch.isRunning && currentQuestionIndex < questions.length && currentQuestionIndex < questionTimes.length) {
      questionTimes[currentQuestionIndex] += _questionStopwatch.elapsed;
    }
    _questionStopwatch.stop(); // Stop stopwatch for the current question
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

  void _toggleMarkForReview() {
    setState(() {
      if (_markedForReview.contains(currentQuestionIndex)) {
        _markedForReview.remove(currentQuestionIndex);
      } else {
        _markedForReview.add(currentQuestionIndex);
      }
    });
  }

  void _clearSelectedAnswer() {
    setState(() {
      _selectedAnswers.remove(currentQuestionIndex);
    });
  }

  void _goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      _saveCurrentQuestionTime(); // Save time for the question user is leaving

      setState(() {
        currentQuestionIndex = index;
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
        showNavigator = false;
        _startQuestionTimer(resume: true); // Start timer for the new current question
      });
    }
  }

  Future<void> _confirmAndSubmitTest({bool autoSubmitted = false}) async {
    _saveCurrentQuestionTime(); // Ensure current question's time is saved

    int answeredCount = 0;
    int unansweredCount = 0;
    int markedForReviewAnsweredCount = 0;
    int markedForReviewUnansweredCount = 0;

    for (int i = 0; i < questions.length; i++) {
      bool isAnswered = _selectedAnswers.containsKey(i) && _selectedAnswers[i]!.isNotEmpty;
      bool isMarked = _markedForReview.contains(i);

      if (isAnswered) {
        answeredCount++;
        if (isMarked) {
          markedForReviewAnsweredCount++;
        }
      } else {
        unansweredCount++;
        if (isMarked) {
          markedForReviewUnansweredCount++;
        }
      }
    }

    final bool? shouldSubmit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
        final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;
        final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
        final Color dialogBackgroundColor = isDarkTheme? Colors.grey.shade900 : Colors.white;

        // Automatically pop and submit if autoSubmitted is true
        if (autoSubmitted) {
          Future.delayed(const Duration(seconds: 2), () { // Give user 2 seconds to see summary
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(true); // Programmatically submit
            }
          });
        }

        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Submit Test?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Theme.of(context).primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your progress summary:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 10),
              Card( // Added Card for better visual grouping
                color: isDarkTheme? Colors.grey.shade800 : Colors.grey.shade100,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      _buildSummaryRow("Total Questions", questions.length, isDarkTheme),
                      _buildSummaryRow("Answered", answeredCount, isDarkTheme, Colors.green),
                      _buildSummaryRow("Unanswered", unansweredCount, isDarkTheme, Colors.red),
                      _buildSummaryRow("Marked & Answered", markedForReviewAnsweredCount, isDarkTheme, Colors.deepPurple),
                      _buildSummaryRow("Marked & Unanswered", markedForReviewUnansweredCount, isDarkTheme, Colors.blueAccent),
                    ],
                  ),
                ),
              ),
              const Divider(height: 25, thickness: 1),
              Text(
                autoSubmitted? "Time limit reached! Submitting your test automatically." : "Are you sure you want to finalize your submission?",
                style: TextStyle(fontSize: 22, color: textColor.withOpacity(0.8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            // Only show "Go Back" button if not auto-submitted
            if (!autoSubmitted)
              TextButton(
                onPressed: () {
                  _startQuestionTimer(resume: true); // Resume question timer
                  Navigator.of(context).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isDarkTheme? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                ),
                child: const Text("Go Back"),
              ),
            ElevatedButton(
              onPressed: autoSubmitted? null : () => Navigator.of(context).pop(true), // Disable button if auto-submitting
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 5,
              ),
              child: const Text("Final Submit"),
            ),
          ],
        );
      },
    );

    if (shouldSubmit == true) {
      _timer.cancel();
      _totalStopwatch.stop();
      _questionStopwatch.stop();
      _submitTestInternal();
    } else {
      // If user cancels submission, main timer is still running.
      // Question timer is restarted by "Go Back" button inside the dialog.
    }
  }

  Widget _buildSummaryRow(String label, int count, bool isDarkTheme, [Color? color]) {
    final Color textColor = isDarkTheme? Colors.white70 : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 15, color: color?? textColor),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color?? textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _submitTestInternal() async {
    // Clear any unfinished test progress because the test is now officially submitted
    await _dbService.clearUnfinishedTest();

    score = 0;
    // Extract user's first selected answer for each question (assuming single choice)
    final userAnswersList = List.generate(questions.length, (i) => _selectedAnswers[i]?.first);

    for (int i = 0; i < questions.length; i++) {
      if (userAnswersList[i]!= null && userAnswersList[i] == questions[i].correctIndex) {
        score++;
      }
    }

    // Determine the actual total time spent on the test
    final Duration totalTimeSpent = _initialDurationSeconds!= null
        ? Duration(seconds: _initialDurationSeconds! - (_remainingSeconds?? 0))
        : (_totalStopwatch.elapsed + _totalTimeSpentActual); // Add previously spent time for count-up

    try {
      await _dbService.saveTestResult(
        testId: widget.testId?? widget.testFile?? 'unknown_test',
        testName: widget.testName?? widget.subject?? 'Test',
        score: score,
        totalQuestions: questions.length,
        timeTaken: totalTimeSpent,
        userAnswers: userAnswersList,
        // questionTimes: questionTimes, // You might want to save this to result for detailed analysis
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
          questionTimes: questionTimes, // Pass individual question times to result screen
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:!showNavigator, // Allow pop if navigator is not open
      onPopInvoked: (didPop) async {
        if (didPop) return; // If the system already handled the pop, do nothing

        if (showNavigator) {
          // If navigator is open, just close it and don't pop the screen
          setState(() {
            showNavigator = false;
          });
          return;
        }

        // Standard exit test dialog flow
        _questionStopwatch.stop(); // Stop current question timer before dialog
        _saveCurrentQuestionTime(); // Save time for the question user is leaving

        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test?'),
            content: const Text('Your progress will be saved. Do you want to exit?'),
            actions: [
              TextButton(
                onPressed: () {
                  _startQuestionTimer(resume: true); // Resume question timer if cancelled
                  Navigator.of(context).pop(false); // Do not pop the screen
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  _timer.cancel(); // Cancel main test timer
                  _totalStopwatch.stop(); // Stop total elapsed stopwatch
                  _questionStopwatch.stop(); // Stop current question stopwatch
                  _saveProgress(); // Save all current progress
                  Navigator.of(context).pop(true); // Allow popping the screen
                },
                child: const Text('Save & Exit'),
              ),
            ],
          ),
        );
        if (shouldPop?? false) {
          if (mounted) Navigator.of(context).pop(); // Actually pop the screen if user confirmed
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.testName?? "${widget.subject} Test"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 20, color: Theme.of(context).appBarTheme.foregroundColor),
                  const SizedBox(width: 4),
                  Center(
                    child: Text(
                      _initialDurationSeconds!= null? _formatSeconds(_remainingSeconds?? 0) : _formatDuration(_totalElapsed),
                      style: TextStyle(
                        color: Theme.of(context).appBarTheme.foregroundColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
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
          final themeNotifier = Provider.of<ThemeNotifier>(context);
          final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;
          final Color primaryTextColor = isDarkTheme? Colors.white : Colors.black87;

          if (isLoading) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
          }

          if (questions.isEmpty) {
            return Center(child: Text("No Questions Available.", style: TextStyle(color: primaryTextColor)));
          }

          final Color borderColor = isDarkTheme? Colors.grey.shade600 : Colors.grey.shade300;
          final Color selectedBorderColor = Theme.of(context).primaryColor;
          final Color unselectedAnswerColor = isDarkTheme? Colors.grey.shade800 : Colors.white;
          final Color navigatorPanelColor = isDarkTheme? Colors.grey.shade900 : Colors.white;

          // New Color Coding for Navigation Panel
          final Color navCurrentColor = Theme.of(context).primaryColor;
          final Color navAnsweredColor = Colors.green.shade600;
          final Color navMarkedColor = Colors.purple.shade400;
          final Color navAnsweredMarkedColor = Colors.teal.shade500;
          final Color navUnansweredColor = isDarkTheme? Colors.grey.shade700 : Colors.grey.shade300;

          const double navigatorPanelWidth = 250.0;
          const double toggleButtonTopPosition = 550.0;

          return GestureDetector(
            onTap: () {
              if (showNavigator) {
                setState(() {
                  showNavigator = false;
                });
              }
            },
            child: Stack(
              children: [
                AbsorbPointer(
                  absorbing: showNavigator,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: questions.length,
                    onPageChanged: (index) {
                      _saveCurrentQuestionTime(); // Save time for the question user is leaving

                      setState(() {
                        currentQuestionIndex = index;
                        _startQuestionTimer(resume: true); // Start timer for the new current question
                      });
                    },
                    itemBuilder: (context, qIndex) {
                      final questionDataForPage = questions[qIndex];
                      final bool isCurrentQuestionPage = (qIndex == currentQuestionIndex);

                      final bool isQuestionMarkedForReview = _markedForReview.contains(qIndex);

                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Question ${currentQuestionIndex + 1} of ${questions.length}",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
                                    ),
                                    if (isQuestionMarkedForReview)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: Icon(
                                          Icons.star,
                                          color: isDarkTheme? Colors.yellow.shade200 : Colors.amber,
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                                Text(
                                  "Q-Time: ${_formatQuestionDuration(questionTimes[currentQuestionIndex] + _questionStopwatch.elapsed)}",
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              selectedLanguage == "en"? questionDataForPage.questionEn : questionDataForPage.questionTe,
                              style: TextStyle(fontSize: 18, color: primaryTextColor),
                            ),
                            const SizedBox(height: 8),
                            if (questionDataForPage.category!= null && questionDataForPage.category!.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDarkTheme? Colors.teal.shade700 : Colors.teal.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Category: ${questionDataForPage.category}",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkTheme? Colors.white : Colors.black87),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView.builder(
                                itemCount: questionDataForPage.optionsEn.length,
                                itemBuilder: (context, index) {
                                  List<String> labels = ["A", "B", "C", "D"];
                                  // Check if the current option is the *first* selected option for this question
                                  // Assuming single answer for display based on current UI
                                  bool isSelected = (_selectedAnswers[qIndex]?.firstOrNull == index);
                                  return GestureDetector(
                                    onTap: isCurrentQuestionPage? () {
                                      setState(() {
                                        // Store as a list containing a single selected option
                                        _selectedAnswers[qIndex] = [index];
                                      });
                                    } : null,
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
                                              selectedLanguage == "en"? questionDataForPage.optionsEn[index] : questionDataForPage.optionsTe[index],
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
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _markedForReview.contains(currentQuestionIndex)?
                                        [Colors.deepPurple.shade300, Colors.deepPurple.shade700] :
                                        [Colors.deepOrange.shade300, Colors.deepOrange.shade700],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: isCurrentQuestionPage? _toggleMarkForReview : null,
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _markedForReview.contains(currentQuestionIndex)? Icons.flag : Icons.flag_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _markedForReview.contains(currentQuestionIndex)? "Unmark" : "Mark for Review",
                                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: _selectedAnswers.containsKey(currentQuestionIndex)?
                                        [Colors.red.shade300, Colors.red.shade700] :
                                        [Colors.grey.shade400, Colors.grey.shade600],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          spreadRadius: 1,
                                          blurRadius: 3,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: isCurrentQuestionPage && _selectedAnswers.containsKey(currentQuestionIndex)? _clearSelectedAnswer : null,
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.close, color: Colors.white, size: 20),
                                              const SizedBox(width: 8),
                                              const Text(
                                                "Erase Answer",
                                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDarkTheme? Colors.blueAccent.shade200 : Colors.blue.shade400,
                                    foregroundColor: primaryTextColor,
                                  ),
                                  onPressed: currentQuestionIndex == 0? null : () {
                                    _pageController.previousPage(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: const Text("Previous"),
                                ),
                                SizedBox(
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _confirmAndSubmitTest(autoSubmitted: false),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 5,
                                      shadowColor: Colors.green.shade700.withOpacity(0.5),
                                    ),
                                    icon: const Icon(Icons.check, color: Colors.white),
                                    label: const Text(
                                      "Submit Test",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
                                  onPressed: () {
                                    if (currentQuestionIndex < questions.length - 1) {
                                      _pageController.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    } else {
                                      _confirmAndSubmitTest(autoSubmitted: false);
                                    }
                                  },
                                  child: Text(currentQuestionIndex == questions.length - 1? "Finish" : "Next"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Navigation Panel
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
                        bool isAnswered = _selectedAnswers.containsKey(index) && _selectedAnswers[index]!.isNotEmpty;
                        bool isMarkedForReview = _markedForReview.contains(index);
                        bool isCurrent = currentQuestionIndex == index;

                        Color bgColor;
                        Color textColor = Colors.white;

                        if (isCurrent) {
                          bgColor = navCurrentColor;
                        } else if (isMarkedForReview && isAnswered) {
                          bgColor = navAnsweredMarkedColor;
                        } else if (isMarkedForReview) {
                          bgColor = navMarkedColor;
                        } else if (isAnswered) {
                          bgColor = navAnsweredColor;
                        } else {
                          bgColor = navUnansweredColor;
                          textColor = primaryTextColor; // Use primary text color for unanswered in light mode
                        }

                        return GestureDetector(
                          onTap: () => _goToQuestion(index),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Text(
                                    "${index + 1}",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                ),
                                if (isMarkedForReview)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Icon(
                                      Icons.star,
                                      color: isDarkTheme? Colors.yellow.shade200 : Colors.amber,
                                      size: 14,
                                    ),
                                  ),
                              ],
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
        }),
      ),
    );
  }
}