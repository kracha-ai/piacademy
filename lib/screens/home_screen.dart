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
    final Uri url = Uri.parse("https://youtube.com/@YOUR_CHANNEL");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  "Pi Academy",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Support"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [

              const SizedBox(height: 20),

              // Logo + Title
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/images/logo.png", height: 45),
                  const SizedBox(width: 10),
                  const Text(
                    "Pi Academy",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Grid Section
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
          color: Colors.white,
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
            Image.asset(imagePath, height: 75),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
