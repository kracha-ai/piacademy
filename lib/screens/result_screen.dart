import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';
import '../models/question.dart';

class ResultScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;
  final int score;
  final int total;
  final List<Question> questions;
  final List<int?> userAnswers;
  final Duration totalTime;
  final List<Duration> questionTimes;

  const ResultScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
    required this.score,
    required this.total,
    required this.questions,
    required this.userAnswers,
    required this.totalTime,
    required this.questionTimes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late String _displayLanguage; // "en" or "te"
  String _selectedFilter = "All"; // Default filter option

  // Options for the filter dropdown
  final List<String> _filterOptions = [
    "All",
    "Incorrect",
    "Unanswered",
    "Correct",
  ];

  @override
  void initState() {
    super.initState();
    _displayLanguage = "en"; // Default to English for results review
  }

  // Helper to format duration for display (can be moved to a utility or kept here)
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

  // Filter function to get the relevant questions based on _selectedFilter
  List<int> _getFilteredQuestionIndices() {
    List<int> filteredIndices = [];
    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final userAnswerIndex = widget.userAnswers[i];
      final bool isCorrect = userAnswerIndex == question.correctIndex;
      final bool isAnswered = userAnswerIndex!= null;

      if (_selectedFilter == "All") {
        filteredIndices.add(i);
      } else if (_selectedFilter == "Correct" && isCorrect) {
        filteredIndices.add(i);
      } else if (_selectedFilter == "Incorrect" &&!isCorrect && isAnswered) {
        filteredIndices.add(i);
      } else if (_selectedFilter == "Unanswered" &&!isAnswered) {
        filteredIndices.add(i);
      }
    }
    return filteredIndices;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    final Color primaryTextColor = isDarkTheme? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color highlightColor = Theme.of(context).primaryColor;

    final int correctCount = widget.score;
    final int incorrectCount = widget.questions.where((q) => widget.userAnswers[widget.questions.indexOf(q)]!= null && widget.userAnswers[widget.questions.indexOf(q)]!= q.correctIndex).length;
    final int unansweredCount = widget.total - correctCount - incorrectCount;
    final double percentage = (widget.total > 0)? (widget.score / widget.total) * 100 : 0.0; // Prevent NaN
    final Duration averageTimePerQuestion = Duration(milliseconds: widget.totalTime.inMilliseconds ~/ (widget.total > 0? widget.total : 1)); // Avoid division by zero

    // Get the filtered list of question indices
    final List<int> filteredQuestionIndices = _getFilteredQuestionIndices();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Results"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _displayLanguage = _displayLanguage == "en"? "te" : "en";
              });
            },
            child: Text(
              _displayLanguage == "en"? "తెలుగు" : "English",
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Summary Section ---
            Card(
              elevation: 4,
              color: Theme.of(context).cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "${widget.exam} - ${widget.topic} - ${widget.subject}",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Stack( // To place percentage on score
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: secondaryTextColor.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${widget.score} / ${widget.total}",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              "${percentage.toStringAsFixed(0)}%",
                              style: TextStyle(
                                fontSize: 18,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 15), // Adjusted spacing
                    _buildSummaryRow("Correct:", correctCount.toString(), Colors.green, primaryTextColor),
                    _buildSummaryRow("Incorrect:", incorrectCount.toString(), Colors.red, primaryTextColor),
                    _buildSummaryRow("Unanswered:", unansweredCount.toString(), secondaryTextColor, primaryTextColor),
                    const SizedBox(height: 10),
                    _buildSummaryRow("Total Time:", _formatDuration(widget.totalTime), secondaryTextColor, primaryTextColor),
                    _buildSummaryRow("Avg Time/Q:", _formatDuration(averageTimePerQuestion), secondaryTextColor, primaryTextColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- Question Review Header with Filter ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Question Review:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                Container( // Make dropdown look like a button
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: secondaryTextColor.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline( // Hide default underline
                    child: DropdownButton<String>(
                      value: _selectedFilter,
                      icon: Icon(Icons.arrow_drop_down, color: primaryTextColor),
                      dropdownColor: Theme.of(context).cardColor, // Ensure dropdown background is themed
                      style: TextStyle(color: primaryTextColor, fontSize: 15), // Themed text style for selected value
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedFilter = newValue!;
                        });
                      },
                      items: _filterOptions.map<DropdownMenuItem<String>>((String value) {
                        Color optionColor;
                        if (value == "Correct") {
                          optionColor = Colors.green.shade600;
                        } else if (value == "Incorrect") {
                          optionColor = Colors.red.shade600;
                        } else if (value == "Unanswered") {
                          optionColor = secondaryTextColor; // A neutral grey
                        } else { // "All"
                          optionColor = primaryTextColor;
                        }
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: TextStyle(color: optionColor)), // Themed item text
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- Question Review List ---
            filteredQuestionIndices.isEmpty
                ? Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  "No questions found for the selected filter.",
                  style: TextStyle(fontSize: 16, color: secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredQuestionIndices.length,
              itemBuilder: (context, idx) {
                final originalIndex = filteredQuestionIndices[idx];
                final question = widget.questions[originalIndex];
                final userAnswerIndex = widget.userAnswers[originalIndex];
                final bool isCorrect = userAnswerIndex == question.correctIndex;
                final Duration timeTaken = widget.questionTimes[originalIndex];
                final bool tookTooLong = timeTaken.inSeconds > 15;

                String statusText;
                Color statusColor;
                if (isCorrect) {
                  statusText = "Status: Correct";
                  statusColor = Colors.green.shade600;
                } else if (userAnswerIndex!= null) {
                  statusText = "Status: Incorrect";
                  statusColor = Colors.red.shade600;
                } else {
                  statusText = "Status: Unanswered";
                  statusColor = secondaryTextColor;
                }

                String highlightReason = "";
                if (tookTooLong) {
                  highlightReason = " (Took too long)";
                }

                // --- UPDATED cardHighlightColor Logic ---
                Color cardHighlightColor;
                if (tookTooLong) {
                  // Prioritize orange highlight if took too long
                  cardHighlightColor = isDarkTheme? Colors.orange.shade900 : Colors.orange.shade100;
                } else if (isCorrect) {
                  // Green for correct
                  cardHighlightColor = isDarkTheme? Colors.green.shade900 : Colors.green.shade100;
                } else if (userAnswerIndex!= null) {
                  // Red for incorrect
                  cardHighlightColor = isDarkTheme? Colors.red.shade900 : Colors.red.shade100;
                } else {
                  // Grey for unanswered
                  cardHighlightColor = isDarkTheme? Colors.blueGrey.shade900 : Colors.grey.shade100;
                }
                // --- END UPDATED cardHighlightColor Logic ---

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  elevation: 2,
                  color: cardHighlightColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Theme( // Override expansion tile theme for custom color
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent, // No divider inside ExpansionTile
                    ),
                    child: ExpansionTile(
                      key: PageStorageKey(originalIndex), // Keep tile state across rebuilds
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text(
                        "Q${originalIndex + 1}: ${_displayLanguage == "en"? question.questionEn : question.questionTe}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryTextColor,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$statusText$highlightReason",
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            "Time Taken: ${_formatDuration(timeTaken)}",
                            style: TextStyle(
                              color: tookTooLong? Colors.orange.shade700 : secondaryTextColor,
                              fontSize: 13,
                            ),
                          ),
                          // --- ADDED CATEGORY DISPLAY HERE ---
                          if (question.category!= null && question.category!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                "Category: ${question.category}",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          // --- END ADDED CATEGORY DISPLAY ---
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Options:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
                              ),
                              ...List.generate(question.optionsEn.length, (optionIndex) {
                                bool isSelectedOption = optionIndex == userAnswerIndex;
                                bool isCorrectOption = optionIndex == question.correctIndex;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    "${String.fromCharCode(65 + optionIndex)}. ${_displayLanguage == "en"? question.optionsEn[optionIndex] : question.optionsTe[optionIndex]}",
                                    style: TextStyle(
                                      color: isCorrectOption
                                          ? Colors.green.shade600
                                          : isSelectedOption &&!isCorrectOption
                                          ? Colors.red.shade600
                                          : primaryTextColor,
                                      fontWeight: isCorrectOption || isSelectedOption
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                              Text(
                                "Correct Answer: ${String.fromCharCode(65 + question.correctIndex)}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Solution:",
                                style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor),
                              ),
                              Text(
                                _displayLanguage == "en"? question.solutionEn : question.solutionTe,
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Go to Home",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for summary rows
  Widget _buildSummaryRow(String label, String value, Color valueColor, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: labelColor)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }
}