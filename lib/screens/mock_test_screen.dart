import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'result_screen.dart';
import '../models/question.dart';

class MockTestScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;
  final String testFile;

  const MockTestScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
    required this.testFile,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  List<Question> questions = [];
  List<int?> userAnswers = [];

  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  // ================= LOAD QUESTIONS =================

  Future<void> loadQuestions() async {
    try {
      final data = await rootBundle.loadString(widget.testFile);

      List<Question> loadedQuestions = parseQuestions(data);

      setState(() {
        questions = loadedQuestions;
        userAnswers = List.filled(questions.length, null);
        isLoading = false;
      });
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
      int correctIndex =
      ["A", "B", "C", "D"].indexOf(answerLetter.trim());

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
    return match != null ? match.group(1)!.trim() : "";
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("${widget.subject} Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Question ${currentQuestionIndex + 1} of ${questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              currentQuestion.questionEn,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 6),
            Text(
              currentQuestion.questionTe,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            if (currentQuestion.askedIn.trim().isNotEmpty)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  bool isSelected = selectedAnswerIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedAnswerIndex = index;
                      });
                    },
                    child: Container(
                      margin:
                      const EdgeInsets.only(bottom: 12),
                      padding:
                      const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
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
                              "${currentQuestion.optionsEn[index]}\n${currentQuestion.optionsTe[index]}",
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
                        currentQuestionIndex--;
                        selectedAnswerIndex =
                        userAnswers[currentQuestionIndex];
                      });
                    },
                    child: const Text("Previous"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: selectedAnswerIndex == null
                        ? null
                        : () {
                      userAnswers[currentQuestionIndex] =
                          selectedAnswerIndex;

                      if (currentQuestionIndex <
                          questions.length - 1) {
                        setState(() {
                          currentQuestionIndex++;
                          selectedAnswerIndex =
                          userAnswers[currentQuestionIndex];
                        });
                      } else {
                        score = 0;
                        for (int i = 0;
                        i < questions.length;
                        i++) {
                          if (userAnswers[i] ==
                              questions[i].correctIndex) {
                            score++;
                          }
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ResultScreen(
                                  score: score,
                                  total:
                                  questions.length,
                                  questions: questions,
                                  userAnswers:
                                  userAnswers,
                                ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      currentQuestionIndex ==
                          questions.length - 1
                          ? "Submit Test"
                          : "Next",
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
