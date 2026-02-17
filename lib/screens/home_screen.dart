import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'exam_screen.dart'; // Make sure this file exists

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
          // Use the full width of the container space
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.0),
            // Optional: Add shadow specifically to the container
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              posterPaths[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  ),
                );
              },
            ),
          ),
        );
      },
      options: CarouselOptions(
        height: 160.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        autoPlayAnimationDuration: const Duration(milliseconds: 1200),
        autoPlayCurve: Curves.fastOutSlowIn,
        enlargeCenterPage: true,
        viewportFraction: 0.95, // Increased slightly for better look
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
  final List<String> languages = ["English", "తెలుగు"];
  String selectedLanguage = "English";

  // FIXED: Removed 'const' and changed 'targetScreen' to a Function (WidgetBuilder)
  // This prevents the error and ensures the screen is built fresh on navigation.
  final List<Map<String, dynamic>> gridButtons = [
    {
      'text': 'Mock Tests',
      'iconPath': 'assets/images/test.png',
      'targetScreen': (BuildContext context) => const ExamScreen(),
    },
    {
      'text': 'notes',
      'iconPath': 'assets/images/notes.png',
      'targetScreen': null,
    },
    {
      'text': 'courses',
      'iconPath': 'assets/images/courses.png',
      'targetScreen': null,
    },
    {
      'text': 'Practice',
      'iconPath': 'assets/images/practice.png',
      'targetScreen': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pi Academy"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              setState(() {
                selectedLanguage = result;
              });
            },
            itemBuilder: (BuildContext context) => languages
                .map((String lang) => PopupMenuItem<String>(
              value: lang,
              child: Text(lang),
            ))
                .toList(),
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // 1. POSTER SECTION
            const PosterSection(),

            const SizedBox(height: 24),

            // 2. SQUARED BUTTONS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemCount: gridButtons.length,
                itemBuilder: (context, index) {
                  final button = gridButtons[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        if (button['targetScreen'] != null) {
                          // Execute the builder function to get the widget
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: button['targetScreen'] as WidgetBuilder,
                            ),
                          );
                        } else {
                          print("${button['text']} feature not implemented yet");
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            button['iconPath'],
                            width: 60,
                            height: 60,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, size: 40, color: Colors.red);
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            button['text'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // 3. MORE CONTENT LIST
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "More Content Coming Soon:",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Using List.generate is often cleaner than a for-loop inside children
                  ...List.generate(8, (index) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blueGrey, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Placeholder item ${index + 1} for articles, updates, etc.",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.school, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}