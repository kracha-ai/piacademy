import 'package:flutter/material.dart';
import 'subject_screen.dart';

class TopicScreen extends StatelessWidget {

  final String examName;

  const TopicScreen({super.key, required this.examName});

  @override
  Widget build(BuildContext context) {

    List<String> topics = [
      "Aptitude",
      "Reasoning",
      "GS",
      "English",
      "Science"
    ];

    Map<String, Color> topicColors = {
      "Aptitude": Colors.orange.shade100,
      "Reasoning": Colors.teal.shade100,
      "GS": Colors.green.shade100,
      "English": Colors.pink.shade100,
      "Science": Colors.blue.shade100,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text("$examName Topics"),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        itemBuilder: (context, index) {

          String topicName = topics[index];

          return Card(
            elevation: 6,
            color: topicColors[topicName],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 14),
              title: Text(
                topicName,
                style: const TextStyle(
                  fontSize: 18,
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
                    builder: (context) => SubjectScreen(
                      examName: examName,
                      topicName: topicName,
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
