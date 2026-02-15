import 'package:flutter/material.dart';
import '../data/question_data.dart';
import 'result_screen.dart';

class MockTestScreen extends StatefulWidget {
  final String topic;

  MockTestScreen({required this.topic});

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
    }
    else if (widget.topic == "Chemistry") {
      questions = chemistryQuestions;
    }
    else if (widget.topic == "Biology") {
      questions = biologyQuestions;
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
        appBar: AppBar(title: Text("Mock Test")),
        body: Center(child: Text("No Questions Available")),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.topic} Test"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            Text(
              "Question ${currentQuestionIndex + 1} / ${questions.length}",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 20),

            Text(
              currentQuestion.question,
              style: TextStyle(fontSize: 18),
            ),

            SizedBox(height: 20),

            ...List.generate(
              currentQuestion.options.length,
                  (index) => RadioListTile<int>(
                title: Text(currentQuestion.options[index]),
                value: index,
                groupValue: selectedAnswerIndex,
                onChanged: (value) {
                  setState(() {
                    selectedAnswerIndex = value;
                  });
                },
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed:
              selectedAnswerIndex == null ? null : nextQuestion,
              child: Text(
                  currentQuestionIndex == questions.length - 1
                      ? "Submit"
                      : "Next"),
            )
          ],
        ),
      ),
    );
  }
}
