// lib/models/data_models.dart

import 'dart:convert'; // Required for encoding/decoding the answers map
import 'dart:core';

class UserStats {
  final int id; // It's good practice to have an ID for database records
  final int testsTaken;
  final double avgScore;
  final int timeSpentSeconds; // Store as seconds for easier database handling

  UserStats({
    required this.id,
    required this.testsTaken,
    required this.avgScore,
    required this.timeSpentSeconds,
  });

  // Helper getter to convert seconds back to Duration for display
  Duration get timeSpent => Duration(seconds: timeSpentSeconds);

  // Convert to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'testsTaken': testsTaken,
      'avgScore': avgScore,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  // Create from a Map (retrieved from database)
  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      id: map['id'],
      testsTaken: map['testsTaken'],
      avgScore: map['avgScore'],
      timeSpentSeconds: map['timeSpentSeconds'],
    );
  }
}

class FeaturedTest {
  final String name;
  final String details;

  FeaturedTest({required this.name, required this.details});
}

// --- THIS IS THE UPDATED MODEL FOR SAVING TEST PROGRESS ---
class UnfinishedTest {
  final String testId; // Unique ID from Firestore to identify the test
  final String testName; // For display purposes
  final int currentQuestionIndex; // Where the user left off
  final Map<int, List<int>> selectedAnswers; // Their progress: {questionIndex: [selectedOptionIndex]}
  final int timeSpentSeconds; // How long they've spent on the test
  final List<int>? markedForReviewQuestions; // <--- ADDED THIS NEW FIELD!

  UnfinishedTest({
    required this.testId,
    required this.testName,
    required this.currentQuestionIndex,
    required this.selectedAnswers,
    required this.timeSpentSeconds,
    this.markedForReviewQuestions, // <--- ADDED TO CONSTRUCTOR!
  });

  // Helper for displaying duration on HomeScreen (replaces your 'timeIn')
  Duration get timeIn => Duration(seconds: timeSpentSeconds);

  // --- METHODS FOR DATABASE CONVERSION ---

  // Convert an UnfinishedTest object into a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'testId': testId,
      'testName': testName,
      'currentQuestionIndex': currentQuestionIndex,
      // The 'selectedAnswers' Map needs to be converted to a JSON string to be stored in SQLite
      'selectedAnswers': jsonEncode(selectedAnswers.map((key, value) => MapEntry(key.toString(), value))),
      'timeSpentSeconds': timeSpentSeconds,
      'markedForReviewQuestions': markedForReviewQuestions!= null? jsonEncode(markedForReviewQuestions) : null, // <--- SAVED HERE!
    };
  }

  // Create an UnfinishedTest object from a Map (retrieved from database)
  factory UnfinishedTest.fromMap(Map<String, dynamic> map) {
    return UnfinishedTest(
      testId: map['testId'],
      testName: map['testName'],
      currentQuestionIndex: map['currentQuestionIndex'],
      // Decode the JSON string back into the 'selectedAnswers' Map
      selectedAnswers: (jsonDecode(map['selectedAnswers']) as Map<String, dynamic>).map(
            (key, value) => MapEntry(int.parse(key), (value as List).cast<int>()),
      ),
      timeSpentSeconds: map['timeSpentSeconds'],
      markedForReviewQuestions: map['markedForReviewQuestions']!= null
          ? (jsonDecode(map['markedForReviewQuestions']) as List).cast<int>() // <--- LOADED HERE!
          : null,
    );
  }
}