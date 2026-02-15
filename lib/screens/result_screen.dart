import 'package:flutter/material.dart';
import '../data/question_data.dart';

class ResultScreen extends StatelessWidget {

  final int score;
  final int total;
  final List<Question> questions;
  final List<int?> userAnswers;

  ResultScreen({
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Result")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            Text(
              "Your Score: $score / $total",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {

                  final question = questions[index];
                  final userAnswer = userAnswers[index];
                  final correctIndex = question.correctIndex;

                  final isCorrect = userAnswer == correctIndex;

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            question.question,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          SizedBox(height: 8),

                          Text(
                            "Your Answer: ${userAnswer != null ? question.options[userAnswer] : "Not Answered"}",
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),

                          Text(
                            "Correct Answer: ${question.options[correctIndex]}",
                            style: TextStyle(color: Colors.green),
                          ),

                          SizedBox(height: 8),

                          Text(
                            "Solution: ${question.solution}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Back"),
            )
          ],
        ),
      ),
    );
  }
}
