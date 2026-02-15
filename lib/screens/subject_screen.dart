import 'package:flutter/material.dart';
import 'topic_screen.dart';

class SubjectScreen extends StatelessWidget {

  final String examName;

  SubjectScreen({required this.examName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$examName Subjects"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          buildSubjectTile(context, "General Studies"),
          buildSubjectTile(context, "General Science"),
        ],
      ),
    );
  }

  Widget buildSubjectTile(BuildContext context, String subjectName) {
    return Card(
      child: ListTile(
        title: Text(subjectName),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicScreen(subjectName: subjectName),
            ),
          );
        },
      ),
    );
  }
}
