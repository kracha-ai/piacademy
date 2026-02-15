import 'package:flutter/material.dart';
import 'mock_test_screen.dart';

class SubjectScreen extends StatelessWidget {

  final String examName;
  final String topicName;

  const SubjectScreen({
    super.key,
    required this.examName,
    required this.topicName,
  });

  @override
  Widget build(BuildContext context) {

    List<String> subjects = [];

    if (topicName == "General Studies") {
      subjects = ["Polity", "Geography", "Economics"];
    }
    else if (topicName == "General Science") {
      subjects = ["Physics", "Chemistry", "Biology"];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$examName - $topicName"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(subjects[index]),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockTestScreen(
                      exam: examName,
                      topic: topicName,
                      subject: subjects[index],
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
