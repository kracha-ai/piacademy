import 'package:flutter/material.dart';
import '../data/question_data.dart';
import 'result_screen.dart';

class MockTestScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;

  const MockTestScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
  });

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {

  late List<Question> questions;
  List<int?> userAnswers = [];

  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;

  @override
  void initState() {
    super.initState();

    if (widget.exam == "RRB" &&
        widget.topic == "General Science" &&
        widget.subject == "Physics") {

      questions = rrbGeneralSciencePhysicsQuestions;
    }

    else if (widget.exam == "RRB" &&
        widget.topic == "General Science" &&
        widget.subject == "Chemistry") {

      questions = rrbGeneralScienceChemistryQuestions;
    }

    else if (widget.exam == "RRB" &&
        widget.topic == "General Science" &&
        widget.subject == "Biology") {

      questions = rrbGeneralScienceBiologyQuestions;
    }

    else if (widget.exam == "RRB" &&
        widget.topic == "General Studies" &&
        widget.subject == "Polity") {

      questions = rrbGeneralStudiesPolityQuestions;
    }

    else if (widget.exam == "RRB" &&
        widget.topic == "Aptitude") {

      questions = rrbAptitudeQuestions;
    }

    else {
      questions = [];
    }

    userAnswers = List.filled(questions.length, null);
  }

  void nextQuestion() {

    userAnswers[currentQuestionIndex] = selectedAnswerIndex;

    if (selectedAnswerIndex ==
        questions[currentQuestionIndex].correctIndex) {
      score++;
    }

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: score,
            total: questions.length,
            questions: questions,
            userAnswers: userAnswers,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

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
        title: Text("${widget.topic} Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Question Counter
            Text(
              "Question ${currentQuestionIndex + 1} of ${questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Question Text
            Text(
              currentQuestion.question,
              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 20),

            // Options List
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
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
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.black87
                              : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // Option Letter
                          Text(
                            "${labels[index]}. ",
                            style: TextStyle(
                              fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),

                          // Option Text
                          Expanded(
                            child: Text(
                              currentQuestion.options[index],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
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

            // Next Button
            Row(
              children: [

                // Previous Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    child: const Text(
                      "Previous",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Next / Submit Button
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

                        // Calculate score before submit
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
                                  total: questions.length,
                                  questions: questions,
                                  userAnswers: userAnswers,
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
                      style: const TextStyle(fontSize: 16),
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
