import 'package:flutter/material.dart';
import 'mock_test_screen.dart';

class TopicScreen extends StatelessWidget {

  final String subjectName;

  TopicScreen({required this.subjectName});

  @override
  Widget build(BuildContext context) {

    List<String> topics = [];

    if (subjectName == "General Studies") {
      topics = ["Polity", "Economics", "Geography"];
    } else if (subjectName == "General Science") {
      topics = ["Physics", "Chemistry", "Biology"];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(topics[index]),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MockTestScreen(
                      topic: topics[index],
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
