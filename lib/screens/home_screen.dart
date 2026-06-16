// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'exam_screen.dart'; // For the Action Grid
import 'mock_test_screen.dart'; // For the Featured Tests
import '../services/theme_notifier.dart';

// --- REQUIRED IMPORTS TO MAKE THE DATA CONNECTION WORK ---
import '../services/database_service.dart';
import '../models/data_models.dart';

// --- POSTER SECTION (No changes needed) ---
class PosterSection extends StatefulWidget {
  const PosterSection({super.key});
  @override
  State<PosterSection> createState() => _PosterSectionState();
}
class _PosterSectionState extends State<PosterSection> {
  final List<String> posterPaths = [
    'assets/images/poster1.png',
    'assets/images/poster2.png',
    'assets/images/poster3.png',
  ];
  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: posterPaths.length,
      itemBuilder: (context, index, realIndex) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              posterPaths[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.broken_image, size: 50),
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 110.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
    );
  }
}

// --- HOME SCREEN (UPDATED) ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final DatabaseService _dbService = DatabaseService();

  // 1. State variable to hold the unfinished test data
  UnfinishedTest? _unfinishedTest;

  @override
  void initState() {
    super.initState();
    // 2. Observe app lifecycle changes (e.g., when app is resumed)
    WidgetsBinding.instance.addObserver(this);
    // 3. Check for an unfinished test when the screen loads
    _checkUnfinishedTest();
  }

  @override
  void dispose() {
    // 4. Clean up the observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 5. Re-check for unfinished tests when the user brings the app to the foreground
    if (state == AppLifecycleState.resumed) {
      _checkUnfinishedTest();
    }
  }

  /// Fetches unfinished test progress from the local database.
  void _checkUnfinishedTest() async {
    final test = await _dbService.getUnfinishedTest();
    if (mounted) {
      setState(() {
        _unfinishedTest = test;
      });
    }
  }

  /// Fetches the full test document from Firestore using its ID.
  Future<Map<String, dynamic>?> _fetchTestDocument(String testId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('tests').doc(testId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
    } catch (e) {
      print("Error fetching test document $testId: $e");
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pi Academy"),
        elevation: 1,
        actions: [
          Row(
            children: [
              Icon(isDarkTheme? Icons.dark_mode : Icons.light_mode),
              Switch(
                value: isDarkTheme,
                onChanged: (value) {
                  themeNotifier.toggleTheme();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // 1. TESTS COME FIRST NOW
            _ContinueSection(
              dbService: _dbService,
              unfinishedTest: _unfinishedTest,
              fetchTestDocument: _fetchTestDocument,
              onTestResumed: _checkUnfinishedTest,
            ),
            _PerformanceSnapshot(dbService: _dbService),
            _FeaturedTests(
              dbService: _dbService,
              unfinishedTest: _unfinishedTest,
              fetchTestDocument: _fetchTestDocument,
              onTestResumed: _checkUnfinishedTest,
            ),

            // 2. Tools
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                "Tools & Resources",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const _ActionGrid(),

            const SizedBox(height: 24),

            // 3. YOUTUBE CAROUSEL MOVED TO BOTTOM
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                "Free Learning Videos",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const PosterSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            IconButton(icon: const Icon(Icons.school), onPressed: () {}),
            IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person), onPressed: () {}),
          ],
        ),
      ),
    );
  }
} // <-- THIS CLOSING BRACE WAS MISSING

// --- Firestore Test Display (No changes needed) ---
class _FirestoreTestDisplay extends StatelessWidget {
  //... your existing code...
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tests').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('No tests found in Firestore.'),
          ));
        }
        return ListView.builder(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var testDocument = snapshot.data!.docs[index];
            Map<String, dynamic> data = testDocument.data()! as Map<String, dynamic>;

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ExpansionTile(
                title: Text(data['name']?? 'Untitled Test', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${data['description']?? 'No description'}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Total Questions: ${data['totalQuestions']}"),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// --- _ContinueSection (UPDATED) ---
class _ContinueSection extends StatelessWidget {
  final DatabaseService dbService;
  final UnfinishedTest? unfinishedTest;
  final Future<Map<String, dynamic>?> Function(String testId) fetchTestDocument;
  final VoidCallback onTestResumed; // To refresh the home screen state

  const _ContinueSection({
    required this.dbService,
    required this.unfinishedTest,
    required this.fetchTestDocument,
    required this.onTestResumed,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    // This widget no longer uses a FutureBuilder; it just displays the data passed to it.
    if (unfinishedTest == null) {
      return const SizedBox.shrink(); // If there's no unfinished test, show nothing.
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.history, size: 40, color: Colors.blueAccent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unfinishedTest!.testName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("You're ${unfinishedTest!.timeIn.inMinutes} mins in. Q${unfinishedTest!.currentQuestionIndex + 1}."),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 1. Fetch the full test data from Firestore
                  final testDoc = await fetchTestDocument(unfinishedTest!.testId);

                  if (testDoc!= null) {
                    // 2. Extract the data needed by MockTestScreen
                    final String testName = testDoc['name']?? 'Untitled Test';
                    final int duration = testDoc['durationMinutes']?? 30;
                    final List<Map<String, dynamic>> questions =
                        (testDoc['questions'] as List?)
                           ?.map((q) => q as Map<String, dynamic>)
                           .toList()?? [];

                    if (questions.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Test has no questions.")));
                      await dbService.clearUnfinishedTest();
                      onTestResumed(); // Refresh home screen to hide this section
                      return;
                    }

                    // 3. Navigate to MockTestScreen. It will handle loading the progress.
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MockTestScreen(
                          testId: unfinishedTest!.testId, // Crucial for loading progress
                          testName: testName,
                          durationMinutes: duration,
                          questions: questions,
                        ),
                      ),
                    );
                    // 4. After returning from MockTestScreen, refresh the home screen state
                    onTestResumed();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Could not find test. It may have been deleted.")),
                    );
                    // Clear the invalid progress from the local DB
                    await dbService.clearUnfinishedTest();
                    onTestResumed();
                  }
                },
                child: const Text("Resume"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- _PerformanceSnapshot (No changes needed) ---
class _PerformanceSnapshot extends StatelessWidget {
  //... your existing code...
  final DatabaseService dbService;
  const _PerformanceSnapshot({required this.dbService});

  String _formatDuration(Duration d) => "${d.inHours}h ${d.inMinutes.remainder(60)}m";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: FutureBuilder<UserStats>(
        future: dbService.getUserStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Card(child: SizedBox(height: 90, child: Center(child: CircularProgressIndicator())));
          }
          if (snapshot.hasError) {
            return const Card(child: SizedBox(height: 90, child: Center(child: Text("Error loading stats."))));
          }
          if (snapshot.hasData) {
            final stats = snapshot.data!;
            return Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn(stats.testsTaken.toString(), "Tests Taken"),
                    _buildStatColumn("${(stats.avgScore * 100).toStringAsFixed(0)}%", "Avg. Score"),
                    _buildStatColumn(_formatDuration(stats.timeSpent), "Time Spent"),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// --- _FeaturedTests (UPDATED) ---
class _FeaturedTests extends StatelessWidget {
  final DatabaseService dbService;
  final UnfinishedTest? unfinishedTest; // New
  final Future<Map<String, dynamic>?> Function(String testId) fetchTestDocument; // New
  final VoidCallback onTestResumed; // New
  const _FeaturedTests({
    required this.dbService,
    required this.unfinishedTest,
    required this.fetchTestDocument,
    required this.onTestResumed,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            "Featured Mock Tests",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 160,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
               .collection('tests')
               .where('isFeatured', isEqualTo: true)
               .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error loading tests"));
              if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());
              final featuredTests = snapshot.data?.docs?? [];
              if (featuredTests.isEmpty) {
                return const Center(child: Text("No featured tests yet."));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featuredTests.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  var data = featuredTests[index].data() as Map<String, dynamic>;
                  String testId = featuredTests[index].id;
                  // Check if this featured test is the unfinished one
                  bool isUnfinishedFeaturedTest = unfinishedTest?.testId == testId;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['name']?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("${data['totalQuestions']?? 0} Questions", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ElevatedButton(
                            onPressed: () async {
                              final String testName = data['name']?? 'Untitled Test';
                              final int duration = data['durationMinutes']?? 30;
                              final List<Map<String, dynamic>> questions =
                                  (data['questions'] as List?)
                                     ?.map((q) => q as Map<String, dynamic>)
                                     .toList()?? [];
                              if (questions.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("This test has no questions yet!")),
                                );
                                return;
                              }
                              // Logic for "Resume Test" (if it's the unfinished one)
                              // OR "Start Test" (if it's a new test)
                              if (isUnfinishedFeaturedTest) {
                                // Fetch the full test data for resuming
                                final testDoc = await fetchTestDocument(testId);
                                if (testDoc!= null) {
                                  // Make sure questions are updated in case Firestore changed
                                  final List<Map<String, dynamic>> resumedQuestions =
                                      (testDoc['questions'] as List?)
                                         ?.map((q) => q as Map<String, dynamic>)
                                         .toList()?? [];
                                  if (resumedQuestions.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error: Test has no questions.")));
                                    await dbService.clearUnfinishedTest();
                                    onTestResumed();
                                    return;
                                  }
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MockTestScreen(
                                        testId: testId,
                                        testName: testName,
                                        durationMinutes: duration,
                                        questions: resumedQuestions,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Could not find test to resume. It may have been deleted.")),
                                  );
                                  await dbService.clearUnfinishedTest();
                                }
                              } else {
                                // Logic for starting a new test
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MockTestScreen(
                                      testId: testId,
                                      testName: testName,
                                      durationMinutes: duration,
                                      questions: questions,
                                    ),
                                  ),
                                );
                              }
                              onTestResumed(); // Refresh the home screen state after returning
                            },
                            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                            child: Row( // Use a Row to potentially add an icon
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isUnfinishedFeaturedTest)...[
                                  const Icon(Icons.refresh, size: 20), // Reload icon for resume
                                  const SizedBox(width: 8),
                                ],
                                Text(isUnfinishedFeaturedTest? "Resume Test" : "Start Test"),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
// --- _ActionGrid (No changes needed) ---
class _ActionGrid extends StatelessWidget {
  //... your existing code...
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> gridButtons = [
      // --- THIS LINE IS NOW CORRECTED ---
      // It points to your list of exams, which doesn't need any data passed to it.
      {'text': 'Mock Tests', 'iconPath': 'assets/images/test.png', 'targetScreen': (BuildContext context) => const ExamScreen()},
      {'text': 'Courses', 'iconPath': 'assets/images/courses.png', 'targetScreen': null},
      {'text': 'Notes', 'iconPath': 'assets/images/notes.png', 'targetScreen': null},
      {'text': 'Analysis', 'iconPath': 'assets/images/analysis.png', 'targetScreen': null},
      {'text': 'Review', 'iconPath': 'assets/images/review.png', 'targetScreen': null},
      {'text': 'Quiz', 'iconPath': 'assets/images/quiz.png', 'targetScreen': null},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemCount: gridButtons.length,
        itemBuilder: (context, index) {
          final button = gridButtons[index];
          final bool isProminent = (button['text'] == 'Analysis' || button['text'] == 'Quiz');

          return Card(
            elevation: isProminent? 4 : 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                if (button['targetScreen']!= null) {
                  Navigator.push(context, MaterialPageRoute(builder: button['targetScreen'] as WidgetBuilder));
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    button['iconPath'],
                    width: isProminent? 50.0 : 40.0,
                    height: isProminent? 50.0 : 40.0,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.error, size: isProminent? 50.0 : 40.0),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    button['text'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isProminent? 15.0 : 14.0,
                      fontWeight: isProminent? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}