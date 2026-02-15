import 'package:flutter/material.dart';
import 'mock_test_screen.dart';
import 'exam_screen.dart';
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Pi Academy"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildButton(context, "Syllabus"),
            SizedBox(height: 20),
            buildButton(context, "Mock Tests"),
            SizedBox(height: 20),
            buildButton(context, "Notes and Material"),
          ],
        ),
      ),
    );
  }

  Widget buildButton(BuildContext context, String title) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          if (title == "Mock Tests") {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExamScreen(),
              ),
            );
          }
        },
        child: Text(title, style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
