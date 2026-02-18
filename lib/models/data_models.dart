// lib/data_models.dart

import 'dart:core';

class UserStats {
  final int testsTaken;
  final double avgScore; // Use a double from 0.0 to 1.0
  final Duration timeSpent;

  UserStats({
    required this.testsTaken,
    required this.avgScore,
    required this.timeSpent,
  });
}

class FeaturedTest {
  final String name;
  final String details;

  FeaturedTest({required this.name, required this.details});
}

class UnfinishedTest {
  final String name;
  final Duration timeIn;

  UnfinishedTest({required this.name, required this.timeIn});
}