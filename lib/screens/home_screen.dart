import 'package:flutter/material.dart';
import 'exam_screen.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final PageController _pageController =
  PageController(viewportFraction: 0.88);

  int _currentPage = 0;

  final List<String> posters = [
    "assets/images/poster1.png",
    "assets/images/poster2.png",
    "assets/images/poster3.png",
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentPage < posters.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> openYoutube() async {
    //!! IMPORTANT: Replace "@YOUR_CHANNEL" with your actual YouTube channel URL!!
    final Uri url = Uri.parse("https://youtube.com/@Piacademy9");
    if (await canLaunchUrl(url)) { // Added check if URL can be launched
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // You could show a SnackBar or AlertDialog here if the URL can't be launched
      print('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( // <--- MODIFIED AppBar HERE
        backgroundColor: Colors.blue[900], // Changed to a dark blue!
        elevation: 0, // No shadow
        centerTitle: false, // Align title to the left
        title: Row( // Row for logo and text
          children: [
            Image.asset(
              "assets/images/logo.png",
              height: 30, // Adjust logo size for AppBar
              semanticLabel: 'Pi Academy logo',
            ),
            const SizedBox(width: 8),
            const Text(
              "Pi Academy",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22, // Adjust font size for AppBar
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white), // Set hamburger icon color to white
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // DrawerHeader for branding or user info
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue), // Blue background for header
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Pi Academy", // Could be app name or a user's name
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black), // Icon black for contrast on white drawer background
              title: const Text("Home", style: TextStyle(color: Colors.black)), // Text black for contrast
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.black), // Icon black for contrast
              title: const Text("Support", style: TextStyle(color: Colors.black)), // Text black for contrast
              onTap: () => Navigator.pop(context),
            ),
            // Add more ListTile items for other menu options here
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          // Main background gradient is blue
          gradient: LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF2196F3)], // Darker to lighter blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea( // No longer needs a SizedBox(height: 20) at the top
          child: Column(
            children: [

              // The logo and title previously here are now in the AppBar
              // So, you can remove this section:
              /*
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/logo.png",
                    height: 45,
                    semanticLabel: 'Pi Academy logo', // Added semantic label for accessibility
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Pi Academy",
                    style: TextStyle(
                      color: Colors.white, // Text remains white for contrast on blue background
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              */

              // Grid Section (Square Buttons)
              Expanded(
                child: GridView.count(
                  padding: const EdgeInsets.all(20),
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    buildSquareButton(
                      context,
                      "Syllabus",
                      "assets/images/syllabus.png",
                          () {},
                    ),
                    buildSquareButton(
                      context,
                      "Mock Tests",
                      "assets/images/test.png",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExamScreen(),
                          ),
                        );
                      },
                    ),
                    buildSquareButton(
                      context,
                      "Notes",
                      "assets/images/notes.png",
                          () {},
                    ),
                    buildSquareButton(
                      context,
                      "Results",
                      "assets/images/result.png",
                          () {},
                    ),
                  ],
                ),
              ),

              // 🔥 AUTO SCROLLING POSTERS
              const SizedBox(height: 10),

              SizedBox(
                height: 160,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: posters.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: openYoutube,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            posters[index],
                            fit: BoxFit.cover,
                            semanticLabel: 'Promotional poster ${index + 1}', // Added semantic label
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent square buttons
  Widget buildSquareButton(
      BuildContext context,
      String title,
      String imagePath,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, // Button background color is white
          // Reverted borderRadius to 20 for rounded rectangles, adjust if you want circular
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 65,
              semanticLabel: '$title icon', // Added semantic label based on button title
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Text inside button is black
              ),
            ),
          ],
        ),
      ),
    );
  }
}