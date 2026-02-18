// lib/database_service.dart

import 'dart:async';
import '../models/data_models.dart'; // Import our new models

class DatabaseService {

  // Simulates fetching the user's overall stats
  Future<UserStats> getUserStats() async {
    // In a real app, you would query your database here.
    // We use Future.delayed to simulate a network/database delay.
    await Future.delayed(const Duration(milliseconds: 800));

    // Return real data (or what would be real data)
    return UserStats(
      testsTaken: 37,
      avgScore: 0.81, // 81%
      timeSpent: const Duration(hours: 21, minutes: 45),
    );
  }

  // Simulates fetching the list of featured tests
  Future<List<FeaturedTest>> getFeaturedTests() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      FeaturedTest(name: "Full Syllabus Mock Test #8", details: "100 Questions • 90 mins"),
      FeaturedTest(name: "Thermodynamics Special", details: "40 Questions • 30 mins"),
      FeaturedTest(name: "Algebra Practice Set", details: "50 Questions • 45 mins"),
    ];
  }

  // Simulates checking if there's an unfinished test
  // It might return null if there are no unfinished tests.
  Future<UnfinishedTest?> getUnfinishedTest() async {
    await Future.delayed(const Duration(milliseconds: 300));

    // Change this to 'return null;' to see the card disappear!
    return UnfinishedTest(
      name: "Modern Physics Mock Test #2",
      timeIn: const Duration(minutes: 19),
    );
  }
}