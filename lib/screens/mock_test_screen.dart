import 'dart:async'; // Import for Timer
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      print("Error loading questions: $e");
      setState(() {
        isLoading = false;
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mock Test")),
        body: const Center(child: Text("No Questions Available")),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    const double navigatorPanelWidth = 250.0;
    const double toggleButtonTopPosition = 550.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        title: Text("${widget.subject} Test"),
        actions: [
          // Timer display in AppBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Text(
                _formatDuration(_totalElapsed), // Total time
                style: const TextStyle(
                  color: Colors.white,
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
              style: const TextStyle(
                color: Colors.white,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Timer for current question
                    Text(
                      "Q-Time: ${_formatDuration(_currentQuestionElapsed)}",
                      style: const TextStyle(
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
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                if (currentQuestion.askedIn.trim().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Asked in: ${currentQuestion.askedIn}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.optionsEn.length,
                    itemBuilder: (context, index) {
                      List<String> labels = ["A", "B", "C", "D"];

                      if (selectedAnswerIndex == null && userAnswers[currentQuestionIndex]!= null) {
                        selectedAnswerIndex = userAnswers[currentQuestionIndex];
                      }

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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${labels[index]}. ",
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  selectedLanguage == "en"
                                      ? currentQuestion.optionsEn[index]
                                      : currentQuestion.optionsTe[index],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
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
                          backgroundColor: Colors.grey,
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
                        child: const Text( // <--- MODIFIED HERE for "Previous"
                          "Previous",
                          style: TextStyle(color: Colors.white), // Set text color to white
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                        ),
                        // onPressed: selectedAnswerIndex == null // REMOVED condition
                        onPressed: () { // Always enabled for navigation
                          // userAnswers[currentQuestionIndex] = selectedAnswerIndex; // Answer saved on selection now

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
              color: Colors.white,
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
                            ? Colors.blue
                            : isAnswered
                            ? Colors.green
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: (isCurrent || isAnswered)? Colors.white : Colors.black,
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
                decoration: const BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Icon(
                  showNavigator? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  color: Colors.white,
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