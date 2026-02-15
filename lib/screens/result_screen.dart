import 'package:flutter/material.dart';
import '../models/question.dart';

class ResultScreen extends StatelessWidget {

  final int score;
  final int total;
  final List<Question> questions;
  final List<int?> userAnswers;

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Result"),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [

            Text(
              "Your Score: $score / $total",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {

                  final question = questions[index];
                  final userAnswer = userAnswers[index];
                  final correctIndex = question.correctIndex;

                  final isCorrect = userAnswer == correctIndex;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // English Question
                          Text(
                            question.questionEn,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          // Telugu Question
                          Text(
                            question.questionTe,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Optional Asked In
                          if (question.askedIn.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "Asked in: ${question.askedIn}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          const SizedBox(height: 6),

                          Text(
                            "Your Answer: ${userAnswer != null ? question.optionsEn[userAnswer] : "Not Answered"}",
                            style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          ),

                          Text(
                            "Correct Answer: ${question.optionsEn[correctIndex]}",
                            style: const TextStyle(
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // English Solution
                          Text(
                            "Solution (EN): ${question.solutionEn}",
                            style: const TextStyle(fontSize: 14),
                          ),

                          const SizedBox(height: 4),

                          // Telugu Solution
                          Text(
                            "Solution (TE): ${question.solutionTe}",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Back"),
            ),
          ],
        ),
      ),
    );
  }
}
