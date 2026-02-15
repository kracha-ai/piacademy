import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mock_test_screen.dart';

class TestListScreen extends StatefulWidget {
  final String exam;
  final String topic;
  final String subject;

  const TestListScreen({
    super.key,
    required this.exam,
    required this.topic,
    required this.subject,
  });

  @override
  State<TestListScreen> createState() => _TestListScreenState();
}

class _TestListScreenState extends State<TestListScreen> {

  List<String> testFiles = [];

  @override
  void initState() {
    super.initState();
    loadTests();
  }

  Future<void> loadTests() async {

    String folderPath =
        "assets/tests/${widget.exam}/${widget.topic}/${widget.subject}/";

    print("Checking folder: $folderPath");

    final jsonString =
    await rootBundle.loadString('${folderPath}tests.json');

    final Map<String, dynamic> jsonData =
    json.decode(jsonString);

    final List<dynamic> tests = jsonData["tests"];

    setState(() {
      testFiles = tests
          .map((test) => folderPath + test["file"])
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} Tests"),
        backgroundColor: Colors.red,
      ),
      body: testFiles.isEmpty
          ? const Center(child: Text("No Tests Available"))
          : ListView.builder(
        itemCount: testFiles.length,
        itemBuilder: (context, index) {

          String filePath = testFiles[index];
          String fileName =
          filePath.split('/').last.replaceAll(".txt", "");

          return Card(
            child: ListTile(
              title: Text(fileName),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MockTestScreen(
                          exam: widget.exam,
                          topic: widget.topic,
                          subject: widget.subject,
                          testFile: filePath,
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
