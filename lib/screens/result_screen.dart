import 'package:flutter/material.dart';
import '../models/question.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final List<Question> questions;
  final List<int?> userAnswers;
  // --- NEW: Add these fields to the ResultScreen's constructor ---
  final Duration totalTime; // Total time spent on the test
  final List<Duration> questionTimes; // Time spent on each question
  // ---------------------------------------------------------------

  const ResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
    // --- NEW: Require these fields in the constructor ---
    required this.totalTime,
    required this.questionTimes,
    // ----------------------------------------------------
  });

  // Helper to format duration for display (can be a top-level function if used in multiple places)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Results"), // Changed from "Result" to "Results" for consistency
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevents going back to the test accidentally
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
          children: [
            Text(
              "Your Score: $score / $total",
              style: const TextStyle(
                fontSize: 24, // Increased font size for score
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // --- NEW: Display Total Time ---
            Text(
              "Total Test Time: ${_formatDuration(totalTime)}",
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
              ),
            ),
            // ---------------------------------
            const SizedBox(height: 20),
            const Text(
              "Detailed Performance:", // Added a new heading for clarity
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final userAnswer = userAnswers[index];
                  final correctIndex = question.correctIndex;

                  final isCorrect = userAnswer == correctIndex;

                  // --- NEW: Get time spent for this question ---
                  final timeSpent = questionTimes[index];
                  final tookTooLong = timeSpent.inSeconds > 15; // Highlight if took more than 15 secs
                  // --------------------------------------------

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    // --- NEW: Highlight questions that took too long ---
                    color: tookTooLong? Colors.orange.shade100 : null,
                    // -------------------------------------------------
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- NEW: Display Question Number and Time ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  "Q${index + 1}: ${question.questionEn}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "Time: ${_formatDuration(timeSpent)}" +
                                    (tookTooLong? " (Slow!)" : ""),
                                style: TextStyle(
                                  fontSize: 12, // Smaller font for time
                                  color: tookTooLong? Colors.red : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // ----------------------------------------------
                          const SizedBox(height: 4),

                          // Telugu Question (Keeping it as you had it)
                          Text(
                            question.questionTe,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey, // Slightly subdue Telugu for primary display
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
                            "Your Answer: ${userAnswer!= null? question.optionsEn[userAnswer] : "Not Answered"}",
                            style: TextStyle(
                              color: isCorrect? Colors.green : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          Text(
                            "Correct Answer: ${question.optionsEn[correctIndex]}",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
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

            const SizedBox(height: 20), // Increased space for the button

            Center( // Center the button
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Changed to blue
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), // Make button larger
                ),
                onPressed: () {
                  // Navigate back to the initial screen, clearing the test stack
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text(
                  "Go to Home", // More descriptive text
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Changed text color to white
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}