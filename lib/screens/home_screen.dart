import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart'; // Import provider
import 'exam_screen.dart'; // Make sure this file exists
import '../services/theme_notifier.dart'; // Import your ThemeNotifier

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
                // Adjust error background color based on theme
                return Container(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey.shade300
                      : Colors.grey.shade700,
                  child: Icon(Icons.broken_image,
                      color: Theme.of(context).iconTheme.color, size: 50),
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
  // REMOVED: bool _isDarkTheme local state, it's now managed globally by ThemeNotifier

  // REMOVED: _toggleTheme local method

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
    // Get the ThemeNotifier instance
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    // Determine if the current theme mode is dark
    final isDarkTheme = themeNotifier.themeMode == ThemeMode.dark;

    return Scaffold(
      // The background color will now be controlled by MaterialApp's theme/darkTheme
      appBar: AppBar(
        title: const Text("Pi Academy"),
        // backgroundColor and foregroundColor will come from MaterialApp's AppBarTheme
        // REMOVED: hardcoded Colors.blue[900] and Colors.white
        elevation: 4,
        actions: [
          // Theme Shifting Widget
          Row(
            children: [
              Icon(
                isDarkTheme? Icons.dark_mode : Icons.light_mode,
                color: Theme.of(context).appBarTheme.foregroundColor, // Use theme's foreground color
              ),
              Switch(
                value: isDarkTheme, // Use the state from ThemeNotifier
                onChanged: (value) {
                  themeNotifier.toggleTheme(); // Call the global toggle method
                },
                activeColor: Theme.of(context).appBarTheme.foregroundColor, // Use theme's foreground color
                inactiveThumbColor: Theme.of(context).appBarTheme.foregroundColor, // Use theme's foreground color
                inactiveTrackColor: Theme.of(context).appBarTheme.foregroundColor?.withOpacity(0.5)?? Colors.white.withOpacity(0.5), // Fallback for null safety
              ),
              const SizedBox(width: 8), // Small spacing
            ],
          ),
          // Search button removed - it's already gone from the previous AppBar code
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
                    color: Theme.of(context).cardColor, // Use theme's card color
                    child: InkWell(
                      onTap: () {
                        if (button['targetScreen']!= null) {
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
                              return Icon(Icons.error,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.error); // Use theme's error color
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            button['text'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.color, // Use theme's default text color
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
                      // Dynamically pick color based on current brightness
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.blue.shade900
                          : Colors.blue.shade300,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    8,
                        (index) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // Dynamic background color for list items
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade100
                            : Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          // Dynamic border color
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            // Dynamic icon color
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.blueGrey
                                : Colors.blueGrey.shade300,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Placeholder item ${index + 1} for articles, updates, etc.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color, // This is fine as bodyMedium?.color is Color? and handles null
                              ),
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
          ], // This is the closing ']' for the Column's children list
        ), // This is the closing ')' for the Column widget
      ), // This is the closing ')' for the SingleChildScrollView widget
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).appBarTheme.backgroundColor, // Use theme's AppBar background color
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: Icon(Icons.home,
                  color: Theme.of(context).appBarTheme.foregroundColor), // Use theme's foreground color
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.school,
                  color: Theme.of(context).appBarTheme.foregroundColor), // Use theme's foreground color
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.notifications,
                  color: Theme.of(context).appBarTheme.foregroundColor), // Use theme's foreground color
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.person,
                  color: Theme.of(context).appBarTheme.foregroundColor), // Use theme's foreground color
              onPressed: () {},
            ),
          ],
        ),
      ),
    ); // This is the closing ')' for the Scaffold widget
  }
}
