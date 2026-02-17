import 'package:flutter/material.dart';
import 'test_list_screen.dart';


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

    if (topicName == "GS") {
      subjects = ["Polity", "Geography", "Economics"];
    }
    else if (topicName == "Science") {
      subjects = ["Physics", "Chemistry", "Biology"];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("$examName - $topicName"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
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
                    builder: (context) => TestListScreen(
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
