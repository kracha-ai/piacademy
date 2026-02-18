import 'package:flutter/material.dart';
import 'topic_screen.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  // Mock data for exams. In a real app, this would come from a database or API.
  // We've added more details to each exam.
  final List<Map<String, dynamic>> _allExams = [
    {
      "name": "RRB",
      "description": "15 Full Tests, 50+ Practice Sets",
      "avgScore": 0.75, // Represents 75%
      "color": Colors.red.shade100,
    },
    {
      "name": "SSC",
      "description": "25 Full Tests, 120+ Practice Sets",
      "avgScore": 0.68, // Represents 68%
      "color": Colors.purple.shade100,
    },
    {
      "name": "UPSC",
      "description": "10 Full Tests, 80+ Practice Sets",
      "avgScore": 0.82, // Represents 82%
      "color": Colors.green.shade100,
    },
    {
      "name": "Bank",
      "description": "30 Full Tests, 200+ Practice Sets",
      "avgScore": 0.0, // Represents 0% (not started)
      "color": Colors.blue.shade100,
    }
  ];

  // This list will hold the exams that are currently visible (for search).
  List<Map<String, dynamic>> _foundExams = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    _foundExams = _allExams;
    super.initState();
  }

  // --- Search Function ---
  void _runFilter(String enteredKeyword) {
    List<Map<String, dynamic>> results = [];
    if (enteredKeyword.isEmpty) {
      results = _allExams;
    } else {
      results = _allExams
          .where((exam) =>
          exam['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      _foundExams = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Exam"),
        // The AppBar color will be handled by your app's theme now
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- NEW: Search Bar ---
            TextField(
              controller: _searchController,
              onChanged: _runFilter,
              decoration: InputDecoration(
                labelText: 'Search for an exam',
                suffixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // --- List of Exams ---
            Expanded(
              child: _foundExams.isNotEmpty
                  ? ListView.builder(
                itemCount: _foundExams.length,
                itemBuilder: (context, index) {
                  final exam = _foundExams[index];
                  final String examName = exam['name'];
                  final String description = exam['description'];
                  final double avgScore = exam['avgScore'];
                  final Color color = exam['color'];

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias, // Ensures content respects the border radius
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicScreen(examName: examName),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Exam Name and Details ---
                            Text(
                              examName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 16),

                            // --- NEW: Progress Bar and Score ---
                            if (avgScore > 0)...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: avgScore,
                                  minHeight: 8,
                                  backgroundColor: Colors.black.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Average Score: ${(avgScore * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ] else...[
                              // --- Show a "Start Practicing" message if no progress ---
                              Text(
                                "You haven't tried this yet. Start practicing!",
                                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w500),
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : const Center(
                child: Text(
                  'No exams found. Try a different search term!',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}