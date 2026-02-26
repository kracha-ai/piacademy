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
  late String _displayLanguage; // Stores the currently selected display language ("en" or "te").
  String _selectedFilter = "All"; // Stores the currently selected filter option for questions.
  // Stores a controller for each ExpansionTile to programmatically expand/collapse them.
  final Map<int, ExpansionTileController> _expansionControllers = {};
  // Tracks the global state of the "Expand All/Collapse All" button.
  bool _allExpanded = false; // Initially false, meaning button shows "Expand All" and tiles are collapsed.

  // List of available filter options for the chips.
  final List<String> _filterOptions = [
    "All",
    "Incorrect",
    "Unanswered",
    "Correct",
  ];

  @override
  void initState() {
    super.initState();
    _displayLanguage = "en"; // Sets the default display language to English.
    _initializeExpansionControllers(); // Initializes controllers for all questions.
  }

  void _initializeExpansionControllers() {
    // Iterates through existing controllers and removes any that are no longer associated with questions.
    _expansionControllers.keys.toList().forEach((key) {
      if (key >= widget.questions.length) {
        _expansionControllers.remove(key);
      }
    });

    // Creates new ExpansionTileControllers for questions that don't yet have one.
    for (int i = 0; i < widget.questions.length; i++) {
      if (!_expansionControllers.containsKey(i)) {
        _expansionControllers[i] = ExpansionTileController();
      }
    }
    // Resets the global 'all expanded' flag to false, as tiles start collapsed by default.
    _allExpanded = false;
  }

  @override
  void didUpdateWidget(covariant ResultScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-initializes controllers if the list of questions changes to ensure proper mapping.
    if (widget.questions!= oldWidget.questions) {
      _initializeExpansionControllers();
    }
  }

  @override
  void dispose() {
    // ExpansionTileController instances do not typically require explicit disposal.
    super.dispose();
  }

  // Helper function to format Duration objects into a user-friendly string (e.g., "05:30").
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

  // Filters the list of question indices based on the currently selected filter option.
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

  // Toggles the expansion state of all currently filtered ExpansionTiles.
  void _toggleAllExpansionTiles() {
    final List<int> currentFilteredIndices = _getFilteredQuestionIndices(); // Gets indices of questions currently displayed.
    if (currentFilteredIndices.isNotEmpty) {
      setState(() {
        _allExpanded =!_allExpanded; // Toggles the state of the "Expand All" button text.
      });

      // Iterates through filtered questions and expands/collapses their tiles using their controllers.
      for (int index in currentFilteredIndices) {
        if (_expansionControllers.containsKey(index)) { // Checks if a controller exists for the index.
          if (_allExpanded) {
            _expansionControllers[index]!.expand(); // Expands the tile.
          } else {
            _expansionControllers[index]!.collapse(); // Collapses the tile.
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Accesses the ThemeNotifier to determine current theme mode (dark/light).
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    // Defines text colors based on the current theme.
    final Color primaryTextColor = isDarkTheme? Colors.white : Colors.black87;
    final Color secondaryTextColor = isDarkTheme? Colors.grey.shade400 : Colors.grey.shade700;
    final Color highlightColor = Theme.of(context).primaryColor;

    // Calculates counts for correct, incorrect, and unanswered questions.
    final int correctCount = widget.score;
    final int incorrectCount = widget.questions.where((q) => widget.userAnswers[widget.questions.indexOf(q)]!= null && widget.userAnswers[widget.questions.indexOf(q)]!= q.correctIndex).length;
    final int unansweredCount = widget.total - correctCount - incorrectCount;
    // Calculates the percentage score, preventing division by zero.
    final double percentage = (widget.total > 0)? (widget.score / widget.total) * 100 : 0.0;

    // Determines performance text and color based on the percentage score.
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

    // Calculates the average time spent per question.
    final Duration averageTimePerQuestion = Duration(milliseconds: widget.totalTime.inMilliseconds ~/ (widget.total > 0? widget.total : 1));

    // Gets the indices of questions that match the current filter.
    final List<int> filteredQuestionIndices = _getFilteredQuestionIndices();

    // Initializes variables for analysis insights (category weakness and slowest questions).
    String categoriesWithWeakness = "N/A";
    Map<String, List<bool>> categoryPerformance = {};
    List<Map<String, dynamic>> answeredQuestionTimes = [];
    final int SLOW_THRESHOLD_SECONDS = 25;

    // Performs analysis if there are questions.
    if (widget.questions.isNotEmpty) {
      for (int i = 0; i < widget.questions.length; i++) {
        final question = widget.questions[i];
        final userAnswerIndex = widget.userAnswers[i];
        final bool isCorrect = userAnswerIndex == question.correctIndex;
        final bool isAnswered = userAnswerIndex!= null;
        final Duration timeTaken = widget.questionTimes[i];

        // Tracks performance per category.
        if (question.category!= null && question.category!.isNotEmpty) {
          if (!categoryPerformance.containsKey(question.category)) {
            categoryPerformance[question.category!] = [];
          }
          if (isAnswered) {
            categoryPerformance[question.category!]!.add(isCorrect);
          }
        }

        // Collects time taken for answered questions.
        if (isAnswered && timeTaken > Duration.zero) {
          answeredQuestionTimes.add({
            'qNum': i + 1,
            'time': timeTaken,
          });
        }
      }

      // Determines categories where performance was weak (all answered questions incorrect).
      List<String> weakCategoriesList = [];
      categoryPerformance.forEach((category, performanceList) {
        if (performanceList.isNotEmpty && performanceList.every((isCorrect) => isCorrect == false)) {
          weakCategoriesList.add(category);
        }
      });

      // Formats the weak categories for display.
      if (weakCategoriesList.isNotEmpty) {
        categoriesWithWeakness = weakCategoriesList.join(", ");
      } else {
        categoriesWithWeakness = "None identified 👍";
      }

      // Sorts answered questions by time taken in descending order to find the slowest.
      answeredQuestionTimes.sort((a, b) => b['time'].compareTo(a['time']));
    }

    // Formats the slowest questions for display.
    String slowestQuestionsDisplay = "N/A";
    if (answeredQuestionTimes.isNotEmpty) {
      List<String> slowQuestionStrings = [];
      List<Map<String, dynamic>> questionsAboveThreshold = answeredQuestionTimes
          .where((q) => q['time'].inSeconds > SLOW_THRESHOLD_SECONDS)
          .toList();

      if (questionsAboveThreshold.isNotEmpty) {
        slowQuestionStrings = questionsAboveThreshold.map((q) => "#${q['qNum']} (${_formatDuration(q['time'])})").toList();
      } else {
        slowQuestionStrings = answeredQuestionTimes
            .take(3)
            .map((q) => "#${q['qNum']} (${_formatDuration(q['time'])})")
            .toList();
      }
      slowestQuestionsDisplay = slowQuestionStrings.join(", ");
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test Results"), // Title of the app bar.
        actions: [
          // Button to toggle display language.
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
      body: Stack( // Using Stack to position the "Expand All/Collapse All" FAB freely.
        children: [
          SingleChildScrollView( // Allows the main content to be scrollable.
            padding: const EdgeInsets.all(16.0), // Padding around the content.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches children horizontally.
              children: [
                // Card displaying summary of results (score, time, performance).
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
                        // Displays the performance text (e.g., "Excellent Performance").
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
                        Stack( // Used to layer the circular progress indicator and score text.
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              // Animates the circular progress indicator based on percentage.
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: percentage / 100),
                                duration: const Duration(seconds: 1),
                                builder: (context, value, _) => CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 10,
                                  backgroundColor: secondaryTextColor.withOpacity(0.3),
                                  valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${widget.score} / ${widget.total}", // Displays current score out of total.
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTextColor,
                                  ),
                                ),
                                Text(
                                  "${percentage.toStringAsFixed(0)}%", // Displays percentage score.
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
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

                // Section title for analysis insights.
                Text(
                  "Analysis Insights:",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                ),
                const SizedBox(height: 10),
                // Displays analysis insights using chips.
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

                // Header for question review section.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Question Review:",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryTextColor),
                    ),
                    // Removed the TextButton from here, as it's now a FloatingActionButton.
                  ],
                ),
                const SizedBox(height: 10),
                // Row of filter chips for question review.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _filterOptions.map((String filterName) {
                      // Defines colors for each filter chip based on theme and selection status.
                      Color chipBgColor;
                      Color chipSelectedColor;
                      Color chipTextColor;
                      Color chipBorderColor;

                      switch (filterName) {
                        case "All":
                          chipBgColor = isDarkTheme? Colors.grey.shade800 : Colors.grey.shade200;
                          chipSelectedColor = highlightColor;
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
                              _selectedFilter = filterName; // Updates the selected filter.
                              _allExpanded = false; // Resets _allExpanded flag when filter changes.
                            });
                            // Collapses all ExpansionTiles when a new filter is selected.
                            _expansionControllers.values.forEach((controller) => controller.collapse());
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

                // Displays a message if no questions match the current filter.
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
                // Builds a list of ExpansionTiles for each filtered question.
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

                    // Determines icon and color for question status (correct, incorrect, unanswered).
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

                    // Determines status text and color.
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

                    // Adds a note if the user took too long to answer.
                    String highlightReason = "";
                    if (timeTaken.inSeconds > 15) {
                      highlightReason = " (Took too long)";
                    }

                    // Determines card background color based on status and time taken.
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

                    // Retrieves the controller for the current question's ExpansionTile.
                    final ExpansionTileController? controller = _expansionControllers[originalIndex];
                    if (controller == null) {
                      // Logs an error if a controller is unexpectedly missing.
                      debugPrint('Error: No ExpansionTileController found for index $originalIndex.');
                      return const SizedBox.shrink(); // Returns an empty widget to prevent errors.
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      elevation: 2,
                      color: cardHighlightColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Theme( // Overrides the default divider color inside ExpansionTile.
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          key: ValueKey('expansionTile_$originalIndex'), // Unique key for each tile.
                          controller: controller, // Assigns the controller to the ExpansionTile.
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: Icon(
                            statusIcon,
                            color: iconColor,
                            size: 28,
                          ),
                          title: Text(
                            "Q${originalIndex + 1}: ${_displayLanguage == "en"? question.questionEn : question.questionTe}",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
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
                                padding: const EdgeInsets.only(top: 4.0),
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
                              // Displays question category if available.
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
                              // Displays "asked in" information if available.
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
                          // Callback for when an individual tile's expansion state changes.
                          onExpansionChanged: (bool expanded) {
                            // This callback fires when the user manually expands/collapses a tile.
                            // If the global _allExpanded flag is currently true (meaning the button shows "Collapse All")
                            // and the user collapses an individual tile, then the "all expanded" state is broken.
                            // So, we need to reset _allExpanded to false.
                            // We use addPostFrameCallback to ensure this setState happens AFTER the current frame
                            // is built and the ExpansionTile's internal state has settled, avoiding race conditions.
                            if (_allExpanded &&!expanded) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if(mounted) { // Check if the widget is still mounted before calling setState
                                  setState(() {
                                    _allExpanded = false;
                                  });
                                }
                              });
                            } else if (!_allExpanded && expanded) {
                              // If _allExpanded is false, and an individual tile is expanded,
                              // we check if *all* currently filtered tiles are now expanded.
                              // If so, we can set _allExpanded to true.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if(mounted) {
                                  final allFilteredExpandedNow = filteredQuestionIndices.every(
                                          (idx) => _expansionControllers[idx]?.isExpanded == true);
                                  if (allFilteredExpandedNow) {
                                    setState(() {
                                      _allExpanded = true;
                                    });
                                  }
                                }
                              });
                            }
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
                                  // Generates and displays each option for the question.
                                  ...List.generate(question.optionsEn.length, (optionIndex) {
                                    bool isSelectedOption = optionIndex == userAnswerIndex;
                                    bool isCorrectOption = optionIndex == question.correctIndex;

                                    // Determines background color for options based on correctness and user selection.
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
                                  const SizedBox(height: 10),
                                  // Displays the correct answer.
                                  Text(
                                    "Correct Answer: ${String.fromCharCode(65 + question.correctIndex)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Displays the solution.
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
                // The old ElevatedButton for "Go to Home" is removed from here.
              ],
            ),
          ),
          // ADDED: FloatingActionButton for "Expand All/Collapse All" positioned at middle-right.
          Positioned(
            right: 16.0, // Adjusts position from the right edge.
            top: MediaQuery.of(context).size.height * 0.5 - 28.0, // Vertically centers the button.
            child: FloatingActionButton( // Changed from.extended to icon-only.
              onPressed: widget.questions.isNotEmpty? _toggleAllExpansionTiles : null, // Disables button if no questions.
              tooltip: _allExpanded? "Collapse All" : "Expand All", // Provides text hint on long press.
              heroTag: "expandCollapseFAB", // Unique tag for multiple FABs.
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9), // Slightly transparent for subtle effect.
              foregroundColor: Colors.white,
              child: Icon(_allExpanded? Icons.unfold_less : Icons.unfold_more), // Dynamic icon based on state.
            ),
          ),
        ],
      ),
      // ADDED: Floating action button for "Go to Home" at bottom-right.
      floatingActionButton: FloatingActionButton( // Changed from.extended to icon-only.
        onPressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst); // Navigates back to the first route in the stack.
        },
        tooltip: "Go to Home", // Provides text hint on long press.
        heroTag: "goToHomeFAB", // Unique tag for multiple FABs.
        backgroundColor: Theme.of(context).secondaryHeaderColor.withOpacity(0.9), // Different color for distinction.
        foregroundColor: Colors.white,
        child: const Icon(Icons.home), // Home icon.
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positions the FAB at the bottom-right.
    );
  }

  // Helper widget to build a row for summary details.
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

  // Helper widget to build a "stat chip" for analysis insights.
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
              color: isDarkTheme? color.withOpacity(0.7) : color.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkTheme? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      backgroundColor: isDarkTheme? color.withOpacity(0.2) : color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.5), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}