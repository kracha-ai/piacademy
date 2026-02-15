import 'package:flutter/material.dart';
import '../data/question_data.dart';
import 'result_screen.dart';

class MockTestScreen extends StatefulWidget {
  final String topic;

  const MockTestScreen({super.key, required this.topic});

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

    if (widget.topic == "Physics") {
      questions = physicsQuestions;
    } else if (widget.topic == "Chemistry") {
      questions = chemistryQuestions;
    } else if (widget.topic == "Biology") {
      questions = biologyQuestions;
    } else {
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
          children: [

            // Progress Bar
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.red.shade100,
              color: Colors.red,
              minHeight: 8,
            ),

            const SizedBox(height: 20),

            Text(
              "Question ${currentQuestionIndex + 1} of ${questions.length}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // Question Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentQuestion.question,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {

                  bool isSelected = selectedAnswerIndex == index;

                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: isSelected
                        ? Colors.red.shade100
                        : Colors.white,
                    child: RadioListTile<int>(
                      title: Text(currentQuestion.options[index]),
                      value: index,
                      groupValue: selectedAnswerIndex,
                      activeColor: Colors.red,
                      onChanged: (value) {
                        setState(() {
                          selectedAnswerIndex = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed:
                selectedAnswerIndex == null ? null : nextQuestion,
                child: Text(
                  currentQuestionIndex == questions.length - 1
                      ? "Submit Test"
                      : "Next Question",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

