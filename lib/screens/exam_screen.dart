import 'package:flutter/material.dart';
import 'subject_screen.dart';

class ExamScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Exam"),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          buildExamTile(context, "RRB"),
        ],
      ),
    );
  }

  Widget buildExamTile(BuildContext context, String examName) {
    return Card(
      child: ListTile(
        title: Text(examName),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectScreen(examName: examName),
            ),
          );
        },
      ),
    );
  }
}
