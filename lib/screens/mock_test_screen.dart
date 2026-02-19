import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Add provider import
import '../services/theme_notifier.dart'; // Add theme_notifier import
import 'result_screen.dart';
import '../models/question.dart';

class MockTestScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;
  final String testFile;
  final String language; // "en" or "te"

  const MockTestScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
    required this.testFile,
    required this.language,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  List<Question> questions = [];
  List<int?> userAnswers = [];
  List<Duration> questionTimes = []; // To store time spent on each question

  bool showNavigator = false;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  late String selectedLanguage;

  bool isLoading = true;

  // Timer variables
  late Timer _timer;
  final Stopwatch _totalStopwatch = Stopwatch(); // Tracks total test time
  final Stopwatch _questionStopwatch = Stopwatch(); // Tracks current question time
  Duration _currentQuestionElapsed = Duration.zero; // For display
  Duration _totalElapsed = Duration.zero; // For display

  @override
  void initState() {
    super.initState();
    loadQuestions();
    selectedLanguage = widget.language;
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    _totalStopwatch.stop();
    _questionStopwatch.stop();
    super.dispose();
  }

  // ================= LOAD QUESTIONS =================

  Future<void> loadQuestions() async {
    try {
      final data = await rootBundle.loadString(widget.testFile);

      List<Question> loadedQuestions = parseQuestions(data);

      setState(() {
        questions = loadedQuestions;
        userAnswers = List.filled(questions.length, null);
        questionTimes = List.filled(questions.length, Duration.zero); // Initialize question times
        isLoading = false;
      });

      _startTestTimer(); // Start the timer once questions are loaded
      _startQuestionTimer(); // Start timer for the first question

    } catch (e) {
      // It's good that you're printing the error, consider showing a user-friendly message
      print("Error loading questions: $e");
      setState(() {
        isLoading = false;
        // Optionally, show a dialog or an error message on the screen
      });
    }
  }

  // ================= PARSE FUNCTION =================

  List<Question> parseQuestions(String rawData) {
    List<Question> questionList = [];

    List<String> blocks = rawData.split("Q_EN:");

    for (int i = 1; i < blocks.length; i++) {
      String block = "Q_EN:" + blocks[i];

      String qEn = extract(block, "Q_EN:");
      String qTe = extract(block, "Q_TE:");
      String askedIn = extract(block, "ASKED_IN:");

      List<String> optionsEn = [
        extract(block, "A_EN:"),
        extract(block, "B_EN:"),
        extract(block, "C_EN:"),
        extract(block, "D_EN:")
      ];

      List<String> optionsTe = [
        extract(block, "A_TE:"),
        extract(block, "B_TE:"),
        extract(block, "C_TE:"),
        extract(block, "D_TE:")
      ];

      String answerLetter = extract(block, "ANSWER:");
      int correctIndex = ["A", "B", "C", "D"].indexOf(answerLetter.trim());

      String solEn = extract(block, "SOLUTION_EN:");
      String solTe = extract(block, "SOLUTION_TE:");

      questionList.add(
        Question(
          questionEn: qEn,
          questionTe: qTe,
          optionsEn: optionsEn,
          optionsTe: optionsTe,
          correctIndex: correctIndex,
          solutionEn: solEn,
          solutionTe: solTe,
          askedIn: askedIn,
        ),
      );
    }

    return questionList;
  }

  // ================= HELPER =================

  String extract(String text, String key) {
    RegExp reg = RegExp('$key(.*)');
    var match = reg.firstMatch(text);
    return match!= null? match.group(1)!.trim() : "";
  }

  // ================= TIMER LOGIC =================

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

  void _startQuestionTimer() {
    _questionStopwatch.reset();
    _questionStopwatch.start();
  }

  void _stopAndSaveQuestionTime() {
    _questionStopwatch.stop();
    questionTimes[currentQuestionIndex] = _questionStopwatch.elapsed;
  }

  // Helper to format duration for display
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

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    // Define theme-aware colors
    final Color primaryTextColor = isDarkTheme? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color questionContainerColor = isDarkTheme? Colors.grey.shade800 : Colors.white; // Unused for now, but good to have
    final Color borderColor = isDarkTheme? Colors.grey.shade600 : Colors.grey.shade300;
    final Color selectedBorderColor = Theme.of(context).primaryColor;
    final Color correctHighlightColor = Colors.green.shade700; // Constant green, can be made theme-aware if needed
    final Color incorrectHighlightColor = Colors.red.shade700; // Constant red, can be made theme-aware if needed
    final Color answeredColor = isDarkTheme? Colors.green.shade700 : Colors.green;
    final Color currentQuestionColor = Theme.of(context).primaryColor;
    final Color unselectedAnswerColor = isDarkTheme? Colors.grey.shade800 : Colors.white;
    final Color navigatorPanelColor = isDarkTheme? Colors.grey.shade900 : Colors.white;

    if (isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Theme-aware background
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)), // Theme-aware indicator
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mock Test")),
        body: Center(child: Text("No Questions Available. Check asset paths or JSON.", style: TextStyle(color: primaryTextColor))),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    const double navigatorPanelWidth = 250.0;
    const double toggleButtonTopPosition = 550.0; // Keep fixed for now

    return Scaffold(
      appBar: AppBar(
        // Colors from MaterialApp's AppBarTheme
        title: Text("${widget.subject} Test"),
        actions: [
          // Timer display in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                _formatDuration(_totalElapsed), // Total time
                style: TextStyle( // Make Text style theme-aware
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
              style: TextStyle( // Make Text style theme-aware
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content of the test screen
          Padding(
            padding: const EdgeInsets.all(16.0), // Keep static padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question index and Current Question Timer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question ${currentQuestionIndex + 1} of ${questions.length}",
                      style: TextStyle( // Make Text style theme-aware
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    // Timer for current question
                    Text(
                      "Q-Time: ${_formatDuration(_currentQuestionElapsed)}",
                      style: const TextStyle( // Keep red as a constant for urgency
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ////////////////// QUESTION DISPLAY BOX/////////////////////////
                Text(
                  selectedLanguage == "en"
                      ? currentQuestion.questionEn
                      : currentQuestion.questionTe,
                  style: TextStyle(fontSize: 18, color: primaryTextColor), // Make Text style theme-aware
                ),
                const SizedBox(height: 8),
                if (currentQuestion.askedIn.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDarkTheme? Colors.yellow.shade700 : Colors.yellow.shade100, // Make theme-aware
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Asked in: ${currentQuestion.askedIn}",
                      style: TextStyle( // Make Text style theme-aware
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDarkTheme? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.optionsEn.length,
                    itemBuilder: (context, index) {
                      List<String> labels = ["A", "B", "C", "D"];

                      // Reset selectedAnswerIndex if user has already answered this question
                      // and then navigate back. This ensures the correct answer is shown
                      // when re-visiting a question.
                      selectedAnswerIndex = userAnswers[currentQuestionIndex];

                      bool isSelected = (selectedAnswerIndex == index);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedAnswerIndex = index;
                            userAnswers[currentQuestionIndex] = selectedAnswerIndex;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected? selectedBorderColor.withOpacity(0.1) : unselectedAnswerColor, // Make theme-aware
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? selectedBorderColor // Theme primary color
                                  : borderColor, // Theme-aware border
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${labels[index]}. ",
                                style: TextStyle( // Make Text style theme-aware
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                  color: primaryTextColor,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  selectedLanguage == "en"
                                      ? currentQuestion.optionsEn[index]
                                      : currentQuestion.optionsTe[index],
                                  style: TextStyle( // Make Text style theme-aware
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: primaryTextColor,
                                  ),
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
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDarkTheme? Colors.grey.shade700 : Colors.grey.shade400, // Make theme-aware grey
                          foregroundColor: primaryTextColor, // Make text color theme-aware
                        ),
                        onPressed: currentQuestionIndex == 0
                            ? null
                            : () {
                          setState(() {
                            _stopAndSaveQuestionTime(); // Save time for current question
                            currentQuestionIndex--;
                            selectedAnswerIndex = userAnswers[currentQuestionIndex];
                            _startQuestionTimer(); // Start timer for new current question
                          });
                        },
                        child: const Text("Previous"), // Text color already handled by foregroundColor
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor, // Use theme primary color
                          foregroundColor: Colors.white, // Keep white for contrast on primary color
                        ),
                        onPressed: () { // Always enabled for navigation
                          _stopAndSaveQuestionTime(); // Save time for current question

                          if (currentQuestionIndex < questions.length - 1) {
                            setState(() {
                              currentQuestionIndex++;
                              selectedAnswerIndex = null;
                              _startQuestionTimer(); // Start timer for new current question
                            });
                          } else {
                            // End of test
                            _totalStopwatch.stop(); // Stop total timer
                            _timer.cancel(); // Cancel periodic timer

                            score = 0;
                            for (int i = 0; i < questions.length; i++) {
                              if (userAnswers[i] == questions[i].correctIndex) {
                                score++;
                              }
                            }

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ResultScreen(
                                  exam: widget.exam, // Pass exam name
                                  topic: widget.topic, // Pass topic name
                                  subject: widget.subject, // Pass subject name
                                  score: score,
                                  total: questions.length,
                                  questions: questions,
                                  userAnswers: userAnswers,
                                  totalTime: _totalElapsed, // Pass total time
                                  questionTimes: questionTimes, // Pass individual question times
                                ),
                              ),
                            );
                          }
                        },
                        child: Text( // <--- MODIFIED HERE for "Next" / "Submit Test"
                          currentQuestionIndex == questions.length - 1
                              ? "Submit Test"
                              : "Next",
                          style: const TextStyle(color: Colors.white), // Set text color to white
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // NAVIGATOR PANEL with animation
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: showNavigator? 0 : -navigatorPanelWidth, // Panel slides in/out
            top: 0,
            bottom: 0,
            width: navigatorPanelWidth,
            child: Container(
              color: navigatorPanelColor, // Make theme-aware
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  bool isAnswered = userAnswers[index]!= null;
                  bool isCurrent = currentQuestionIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _stopAndSaveQuestionTime(); // Save time for current question
                        currentQuestionIndex = index;
                        selectedAnswerIndex = userAnswers[index];
                        showNavigator = false; // Close panel after selection
                        _startQuestionTimer(); // Start timer for new current question
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? currentQuestionColor // Theme primary color
                            : isAnswered
                            ? answeredColor // Theme-aware green
                            : isDarkTheme? Colors.grey.shade800 : Colors.grey.shade300, // Theme-aware grey
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (isCurrent || isAnswered)? Colors.white : primaryTextColor, // Make text color theme-aware
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Toggle button (positioned outside the navigator panel itself)
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
                decoration: BoxDecoration( // Make theme-aware
                  color: Theme.of(context).primaryColor, // Use theme primary color
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Icon(
                  showNavigator? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  color: Theme.of(context).appBarTheme.foregroundColor, // Use theme-aware color
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}