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
  final Map<int, ValueNotifier<bool>> _expansionNotifiers = {};
  bool _allExpanded = false; // Track the state of the "Expand All" button

  // Options for the filter chips
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
    _initializeExpansionNotifiers();
  }

  void _initializeExpansionNotifiers() {
    // Dispose notifiers that might be removed
    _expansionNotifiers.forEach((key, notifier) {
      if (key >= widget.questions.length) {
        notifier.dispose();
      }
    });

    // Add new notifiers and ensure existing ones are covered
    for (int i = 0; i < widget.questions.length; i++) {
      if (!_expansionNotifiers.containsKey(i)) {
        _expansionNotifiers[i] = ValueNotifier<bool>(false);
      }
    }

    // Remove any notifiers for questions that no longer exist
    _expansionNotifiers.keys.toList().forEach((key) {
      if (key >= widget.questions.length) {
        _expansionNotifiers.remove(key)?.dispose();
      }
    });

    _allExpanded = false; // Reset expand/collapse state
  }

  @override
  void didUpdateWidget(covariant ResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-initialize if the underlying list of questions changes
    // This check is more robust than just length, comparing the actual questions content
    if (widget.questions!= oldWidget.questions) { // Assuming Question model has operator== defined or this is a new list instance
      _initializeExpansionNotifiers();
    }
  }

  @override
  void dispose() {
    // Dispose all notifiers to prevent memory leaks
    _expansionNotifiers.forEach((key, notifier) => notifier.dispose());
    super.dispose();
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

  // --- FIX: _toggleAllExpansionTiles now re-calculates filtered indices ---
  void _toggleAllExpansionTiles() {
    final List<int> currentFilteredIndices = _getFilteredQuestionIndices(); // <<< FIX IS HERE
    if (currentFilteredIndices.isNotEmpty) {
      setState(() {
        _allExpanded =!_allExpanded;
        for (int index in currentFilteredIndices) {
          _expansionNotifiers[index]?.value = _allExpanded;
        }
      });
    }
  }
  // --- END FIX ---

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

    // To show user performance//
    String performanceText;
    Color performanceColor;

    if (percentage >= 80) {
      performanceText = "Excellent Performance 🎉";
      performanceColor = Colors.green;
    } else if (percentage >= 50) {
      performanceText = "Good Job 👍";
      performanceColor = Colors.orange;
    } else {
      performanceText = "Needs Improvement 📚";
      performanceColor = Colors.red;
    }
    // To show user performance//

    final Duration averageTimePerQuestion = Duration(milliseconds: widget.totalTime.inMilliseconds ~/ (widget.total > 0? widget.total : 1)); // Avoid division by zero

    // Get the filtered list of question indices
    final List<int> filteredQuestionIndices = _getFilteredQuestionIndices();

    // --- REFINED: Calculate Analysis Stats ---
    String categoriesWithWeakness = "N/A"; // Changed from Most Mistakes Category

    // Track all questions by category to find weakness
    Map<String, List<bool>> categoryPerformance = {}; // key: category, value: list of true (correct) or false (incorrect)

    // For slowest questions
    List<Map<String, dynamic>> answeredQuestionTimes = []; // { 'qNum': int, 'time': Duration }
    final int SLOW_THRESHOLD_SECONDS = 25;

    if (widget.questions.isNotEmpty) {
      for (int i = 0; i < widget.questions.length; i++) {
        final question = widget.questions[i];
        final userAnswerIndex = widget.userAnswers[i];
        final bool isCorrect = userAnswerIndex == question.correctIndex;
        final bool isAnswered = userAnswerIndex!= null;
        final Duration timeTaken = widget.questionTimes[i];

        // Categories with Weakness
        if (question.category!= null && question.category!.isNotEmpty) {
          if (!categoryPerformance.containsKey(question.category)) {
            categoryPerformance[question.category!] = [];
          }
          if (isAnswered) { // Only track if answered, unanswered doesn't show strength/weakness
            categoryPerformance[question.category!]!.add(isCorrect);
          }
        }

        // Collect answered questions for slowest time analysis
        if (isAnswered && timeTaken > Duration.zero) { // Exclude truly unanswered (0 time)
          answeredQuestionTimes.add({
            'qNum': i + 1,
            'time': timeTaken,
          });
        }
      }

      // Determine categories with weakness
      List<String> weakCategoriesList = [];
      categoryPerformance.forEach((category, performanceList) {
        if (performanceList.isNotEmpty && performanceList.every((isCorrect) => isCorrect == false)) {
          // If all answered questions in this category were incorrect
          weakCategoriesList.add(category);
        }
      });

      if (weakCategoriesList.isNotEmpty) {
        categoriesWithWeakness = weakCategoriesList.join(", "); // Join multiple weak categories
      } else {
        categoriesWithWeakness = "None identified 👍";
      }

      // Sort answered questions by time taken in descending order (slowest first)
      answeredQuestionTimes.sort((a, b) => b['time'].compareTo(a['time']));
    }

    String slowestQuestionsDisplay = "N/A";
    if (answeredQuestionTimes.isNotEmpty) {
      List<String> slowQuestionStrings = [];
      List<Map<String, dynamic>> questionsAboveThreshold = answeredQuestionTimes
          .where((q) => q['time'].inSeconds > SLOW_THRESHOLD_SECONDS)
          .toList();

      if (questionsAboveThreshold.isNotEmpty) {
        // If any questions are above the threshold, list them all
        slowQuestionStrings = questionsAboveThreshold.map((q) => "#${q['qNum']} (${_formatDuration(q['time'])})").toList();
      } else {
        // Otherwise, show the top 3 slowest (or fewer if less than 3 answered)
        slowQuestionStrings = answeredQuestionTimes
            .take(3)
            .map((q) => "#${q['qNum']} (${_formatDuration(q['time'])})")
            .toList();
      }
      slowestQuestionsDisplay = slowQuestionStrings.join(", ");
    }
    // --- END REFINED: Calculate Analysis Stats ---

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
                    //This actually shows the performance text//
                    Text(
                      performanceText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: performanceColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    //This actually shows the performance text//

                    Stack( // To place percentage on score
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          height: 150,
                          // --- Animated CircularProgressIndicator ---
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: percentage / 100),
                            duration: const Duration(seconds: 1), // Animates over 1 second
                            builder: (context, value, _) => CircularProgressIndicator(
                              value: value,
                              strokeWidth: 10,
                              backgroundColor: secondaryTextColor.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                            ),
                          ),
                          // --- END Animated CircularProgressIndicator ---
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

            // --- Question Analysis Stats Section ---
            Text(
              "Analysis Insights:",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10.0,
              runSpacing: 10.0,
              children: [
                _buildStatChip(
                  "Category Weakness",
                  categoriesWithWeakness,
                  Colors.red.shade700,
                  isDarkTheme,
                ),
                _buildStatChip(
                  "Slowest Questions",
                  slowestQuestionsDisplay,
                  Colors.blue.shade700,
                  isDarkTheme,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // --- END REFINED: Question Analysis Stats Section ---

            // --- Question Review Header with Filter Chips & Expand/Collapse All ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Question Review:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                // --- Expand/Collapse All Button ---
                TextButton(
                  onPressed: widget.questions.isNotEmpty? _toggleAllExpansionTiles : null, // Disable if no questions
                  child: Text(
                    _allExpanded? "Collapse All" : "Expand All", // Dynamic text
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // --- END Expand/Collapse All ---
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft, // Align chips to the left
              child: Wrap(
                spacing: 8.0, // Space between chips
                runSpacing: 4.0, // Space between rows of chips
                children: _filterOptions.map((String filterName) {
                  // --- LOGIC FOR CHIP COLORS ---
                  Color chipBgColor;
                  Color chipSelectedColor;
                  Color chipTextColor;
                  Color chipBorderColor;

                  switch (filterName) {
                    case "All":
                      chipBgColor = isDarkTheme? Colors.grey.shade800 : Colors.grey.shade200;
                      chipSelectedColor = highlightColor; // Your theme's primary color
                      chipTextColor = _selectedFilter == filterName? Colors.white : primaryTextColor;
                      chipBorderColor = _selectedFilter == filterName? highlightColor : secondaryTextColor.withOpacity(0.5);
                      break;
                    case "Correct":
                      chipBgColor = isDarkTheme? Colors.green.shade900 : Colors.green.shade100;
                      chipSelectedColor = Colors.green.shade700;
                      chipTextColor = _selectedFilter == filterName? Colors.white : (isDarkTheme? Colors.green.shade200 : Colors.green.shade800);
                      chipBorderColor = _selectedFilter == filterName? Colors.green.shade700 : Colors.green.shade400;
                      break;
                    case "Incorrect":
                      chipBgColor = isDarkTheme? Colors.red.shade900 : Colors.red.shade100;
                      chipSelectedColor = Colors.red.shade700;
                      chipTextColor = _selectedFilter == filterName? Colors.white : (isDarkTheme? Colors.red.shade200 : Colors.red.shade800);
                      chipBorderColor = _selectedFilter == filterName? Colors.red.shade700 : Colors.red.shade400;
                      break;
                    case "Unanswered":
                      chipBgColor = isDarkTheme? Colors.blueGrey.shade900 : Colors.grey.shade100;
                      chipSelectedColor = isDarkTheme? Colors.blueGrey.shade700 : Colors.grey.shade500;
                      chipTextColor = _selectedFilter == filterName? Colors.white : (isDarkTheme? Colors.blueGrey.shade200 : Colors.grey.shade800);
                      chipBorderColor = _selectedFilter == filterName? (isDarkTheme? Colors.blueGrey.shade700 : Colors.grey.shade500) : secondaryTextColor.withOpacity(0.5);
                      break;
                    default:
                      chipBgColor = isDarkTheme? Colors.grey.shade800 : Colors.grey.shade200;
                      chipSelectedColor = highlightColor;
                      chipTextColor = _selectedFilter == filterName? Colors.white : primaryTextColor;
                      chipBorderColor = _selectedFilter == filterName? highlightColor : secondaryTextColor.withOpacity(0.5);
                  }
                  // --- END LOGIC FOR CHIP COLORS ---

                  return ChoiceChip(
                    label: Text(
                      filterName,
                      style: TextStyle(
                        color: chipTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: _selectedFilter == filterName,
                    selectedColor: chipSelectedColor,
                    backgroundColor: chipBgColor,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filterName;
                          // When filter changes, collapse all (optional, but good UX to reset)
                          _allExpanded = false;
                          _expansionNotifiers.forEach((key, notifier) => notifier.value = false);
                        });
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: chipBorderColor,
                      ),
                    ),
                    elevation: 2,
                    pressElevation: 4,
                  );
                }).toList(),
              ),
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

                // --- Determine status icon and color ---
                IconData statusIcon;
                Color iconColor;

                if (isCorrect) {
                  statusIcon = Icons.check_circle_rounded;
                  iconColor = Colors.green.shade600;
                } else if (userAnswerIndex!= null) {
                  statusIcon = Icons.cancel_rounded;
                  iconColor = Colors.red.shade600;
                } else {
                  statusIcon = Icons.help_outline_rounded;
                  iconColor = secondaryTextColor;
                }
                // --- END status icon and color ---

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
                if (timeTaken.inSeconds > 15) {
                  highlightReason = " (Took too long)";
                }

                // --- UPDATED cardHighlightColor Logic ---
                Color cardHighlightColor;
                if (timeTaken.inSeconds > 15) {
                  cardHighlightColor = isDarkTheme? Colors.orange.shade900 : Colors.orange.shade100;
                } else if (isCorrect) {
                  cardHighlightColor = isDarkTheme? Colors.green.shade900 : Colors.green.shade100;
                } else if (userAnswerIndex!= null) {
                  cardHighlightColor = isDarkTheme? Colors.red.shade900 : Colors.red.shade100;
                } else {
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
                    // Wrap ExpansionTile with ValueListenableBuilder
                    child: Builder( // Added Builder to provide context for debugPrint
                      builder: (context) {
                        // Safe access to notifier
                        final ValueNotifier<bool>? notifier = _expansionNotifiers[originalIndex];
                        if (notifier == null) {
                          debugPrint('Error: No ValueNotifier found for index $originalIndex. '
                              'This should not happen if _initializeExpansionNotifiers is correct.');
                          return const SizedBox.shrink(); // Return an empty widget or a placeholder
                        }
                        return ValueListenableBuilder<bool>(
                          valueListenable: notifier,
                          builder: (context, isExpanded, child) {
                            return ExpansionTile(
                              key: ValueKey('expansionTile_$originalIndex'), // Use ValueKey for external control
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              leading: Icon(
                                statusIcon,
                                color: iconColor,
                                size: 28,
                              ),
                              title: Text(
                                "Q${originalIndex + 1}: ${_displayLanguage == "en"? question.questionEn : question.questionTe}",
                                style: TextStyle(
                                  fontWeight: FontWeight.w700, // Slightly bolder title for questions
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
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0), // Added padding for spacing
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 14,
                                          color: (timeTaken.inSeconds > 15)? Colors.orange.shade700 : secondaryTextColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Time Taken: ${_formatDuration(timeTaken)}",
                                          style: TextStyle(
                                            color: (timeTaken.inSeconds > 15)? Colors.orange.shade700 : secondaryTextColor,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
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
                                  if (question.askedIn.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: highlightColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        question.askedIn,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: highlightColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              initiallyExpanded: isExpanded,
                              onExpansionChanged: (bool expanded) {
                                notifier.value = expanded;
                                setState(() {
                                  final allVisibleExpanded = filteredQuestionIndices.every(
                                          (idx) => _expansionNotifiers[idx]?.value == true);
                                  final allVisibleCollapsed = filteredQuestionIndices.every(
                                          (idx) => _expansionNotifiers[idx]?.value == false);

                                  if (allVisibleExpanded) {
                                    _allExpanded = true;
                                  } else if (allVisibleCollapsed) {
                                    _allExpanded = false;
                                  } else {
                                    _allExpanded = false;
                                  }
                                });
                              },
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
                                      // --- Wrap each option in a Container ---
                                      ...List.generate(question.optionsEn.length, (optionIndex) {
                                        bool isSelectedOption = optionIndex == userAnswerIndex;
                                        bool isCorrectOption = optionIndex == question.correctIndex;

                                        Color optionBgColor;
                                        if (isCorrectOption) {
                                          optionBgColor = Colors.green.withOpacity(0.1);
                                        } else if (isSelectedOption &&!isCorrectOption) {
                                          optionBgColor = Colors.red.withOpacity(0.1);
                                        } else {
                                          optionBgColor = isDarkTheme && isSelectedOption == false
                                              ? Colors.grey.withOpacity(0.05)
                                              : Colors.transparent;
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: optionBgColor,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isCorrectOption
                                                    ? Colors.green.shade400
                                                    : isSelectedOption &&!isCorrectOption
                                                    ? Colors.red.shade400
                                                    : Colors.transparent,
                                                width: 1,
                                              ),
                                            ),
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
                                          ),
                                        );
                                      }),
                                      // --- END Wrap each option in a Container ---
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
                            );
                          },
                        );
                      },
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

  // --- Helper for building Stat Chips ---
  Widget _buildStatChip(String label, String value, Color color, bool isDarkTheme) {
    return Chip(
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: isDarkTheme? color.withOpacity(0.7) : color.withOpacity(0.8), // Softer color for label
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkTheme? Colors.white : Colors.black87, // High contrast for value
            ),
          ),
        ],
      ),
      backgroundColor: isDarkTheme? color.withOpacity(0.2) : color.withOpacity(0.1), // Subtle background
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.5), width: 1), // Border matching theme
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}