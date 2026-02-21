// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <--- NEW: Import Firestore

import 'exam_screen.dart';
import '../services/theme_notifier.dart';

// --- REQUIRED IMPORTS TO MAKE THE DATA CONNECTION WORK ---
import '../services/database_service.dart';
import '../models/data_models.dart';

// --- POSTER SECTION ---
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
            ), // <--- THIS WAS THE MISSING CLOSING PARENTHESIS!
          ),
        );
      },
      options: CarouselOptions(
        height: 160.0,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
    );
  }
}

// --- HOME SCREEN ---
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _dbService = DatabaseService();

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
            const PosterSection(),
            const SizedBox(height: 24),
            _ContinueSection(dbService: _dbService),
            _PerformanceSnapshot(dbService: _dbService),
            // --- NEW: Section to display fetched Firestore Tests ---
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                "My Firestore Tests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _FirestoreTestDisplay(), // <--- NEW WIDGET CALL
            // --- END NEW SECTION ---
            _FeaturedTests(dbService: _dbService),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                "Tools & Resources",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const _ActionGrid(),
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
}

// --- NEW WIDGET TO DISPLAY FIRESTORE TESTS ---
class _FirestoreTestDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>( // <--- StreamBuilder for real-time updates
      stream: FirebaseFirestore.instance.collection('physics_test_1').snapshots(), // <--- Get stream of 'tests' collection
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // If no tests are found
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('No tests found in Firestore. Add one from the console!'),
          ));
        }

        // Display the tests in a ListView
        return ListView.builder(
          physics: NeverScrollableScrollPhysics(), // Important: to allow parent SingleChildScrollView to work
          shrinkWrap: true, // Important: to make ListView take only needed space
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var testDocument = snapshot.data!.docs[index];
            Map<String, dynamic> data = testDocument.data()! as Map<String, dynamic>;

            // Fetch questions subcollection for each test
            return FutureBuilder<QuerySnapshot>( // <--- FutureBuilder for questions subcollection
              future: testDocument.reference.collection('questions').get(),
              builder: (context, questionSnapshot) {
                if (questionSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ListTile(
                      title: Text(data['name']?? 'Untitled Test'),
                      subtitle: LinearProgressIndicator(), // Show loading for questions
                    ),
                  );
                }

                if (questionSnapshot.hasError) {
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: ListTile(
                      title: Text(data['name']?? 'Untitled Test'),
                      subtitle: Text('Error loading questions: ${questionSnapshot.error}', style: TextStyle(color: Colors.red)),
                    ),
                  );
                }

                List<Widget> questionWidgets = [];
                if (questionSnapshot.hasData && questionSnapshot.data!.docs.isNotEmpty) {
                  questionSnapshot.data!.docs.forEach((qDoc) {
                    var qData = qDoc.data() as Map<String, dynamic>;
                    questionWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                        child: Text('- ${qData['text']?? 'Untitled Question'}'),
                      ),
                    );
                  });
                } else {
                  questionWidgets.add(
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                      child: Text(' No questions for this test.'),
                    ),
                  );
                }

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ExpansionTile( // Use ExpansionTile to show/hide questions
                    title: Text(data['name']?? 'Untitled Test', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${data['description']?? 'No description'}\n'
                        'Questions: ${questionSnapshot.data?.docs.length?? 0}, '
                        'Duration: ${data['duration']?? 'N/A'} mins'),
                    children: questionWidgets,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// --- Keep your existing _ContinueSection, _PerformanceSnapshot, _FeaturedTests, _ActionGrid classes as they are ---
//... (your existing classes below)...

class _ContinueSection extends StatelessWidget {
  final DatabaseService dbService;
  const _ContinueSection({required this.dbService});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UnfinishedTest?>(
      future: dbService.getUnfinishedTest(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasData && snapshot.data!= null) {
          final unfinishedTest = snapshot.data!;
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
                          Text(unfinishedTest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text("You're ${unfinishedTest.timeIn.inMinutes} minutes in."),
                        ],
                      ),
                    ),
                    ElevatedButton(onPressed: () {}, child: const Text("Resume")),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _PerformanceSnapshot extends StatelessWidget {
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

class _FeaturedTests extends StatelessWidget {
  final DatabaseService dbService;
  const _FeaturedTests({required this.dbService});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            "Start a New Test",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: FutureBuilder<List<FeaturedTest>>(
            future: dbService.getFeaturedTests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text("Couldn't load tests."));
              }
              if (snapshot.hasData) {
                final featuredTests = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: featuredTests.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final test = featuredTests[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(test.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(test.details, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                              child: const Text("Start Test"),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> gridButtons = [
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
