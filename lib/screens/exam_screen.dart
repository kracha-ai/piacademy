import 'package:flutter/material.dart';
import 'topic_screen.dart';

class ExamScreen extends StatelessWidget {

  const ExamScreen({super.key});

  @override
  Widget build(BuildContext context) {

    List<String> exams = [
      "RRB",
      "SSC",
      "UPSC",
      "Bank"
    ];

    // Color Map
    Map<String, Color> examColors = {
      "RRB": Colors.red.shade100,
      "SSC": Colors.purple.shade100,
      "UPSC": Colors.green.shade100,
      "Bank": Colors.blue.shade100,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Exam"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: exams.length,
        itemBuilder: (context, index) {

          String examName = exams[index];

          return Card(
            elevation: 6,
            color: examColors[examName],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              title: Text(
                examName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicScreen(
                      examName: examName,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
