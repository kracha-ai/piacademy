import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// 1. AppColors Class Definition
class AppColors {
  static const Color background = Color(0xFFF8F9FE);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryText = Color(0xFF1E293B);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color accent = Color(0xFFE11D48);
  static const Color easy = Color(0xFF10B981);
  static const Color medium = Color(0xFFF59E0B);
  static const Color hard = Color(0xFFEF4444);
}

// 2. The Main Widget
class ViewTestsScreen extends StatefulWidget {
  const ViewTestsScreen({super.key});

  @override
  State<ViewTestsScreen> createState() => _ViewTestsScreenState();
}

class _ViewTestsScreenState extends State<ViewTestsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? category;
  String? difficulty;
  String? topic;
  String? exam;
  DateTime? startDate;
  int _currentCount = 0;

  final categories = ['General', 'Physics', 'Chemistry', 'Math', 'Biology'];
  final difficulties = ['Easy', 'Medium', 'Hard'];
  final topics = ['Mechanics', 'Algebra', 'Genetics', 'Organic', 'Arithmetic'];
  final exams = ['SSC', 'UPSC', 'JEE', 'NEET', 'Banking', 'Railway'];

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query =
    FirebaseFirestore.instance.collection('tests').orderBy('createdAt', descending: true);

    if (category != null) query = query.where('category', isEqualTo: category);
    if (difficulty != null) query = query.where('difficulty', isEqualTo: difficulty);
    if (topic != null) query = query.where('topic', isEqualTo: topic);
    if (exam != null) query = query.where('exam', isEqualTo: exam);
    if (startDate != null) query = query.where('createdAt', isGreaterThanOrEqualTo: startDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Library", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                  // Counter
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.analytics_outlined, size: 18, color: AppColors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          "$_currentCount Tests Found",
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search name...",
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),

                  const Divider(height: 40),
                  const Text("FILTERS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 15),

                  _sidebarDropdown("Category", category, categories, (val) => setState(() => category = val)),
                  _sidebarDropdown("Exam", exam, exams, (val) => setState(() => exam = val)),
                  _sidebarDropdown("Topic", topic, topics, (val) => setState(() => topic = val)),

                  // Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Created After", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(startDate == null ? "Select Date" : DateFormat('dd MMM yyyy').format(startDate!)),
                    trailing: const Icon(Icons.calendar_month, size: 20),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => startDate = picked);
                    },
                  ),

                  const SizedBox(height: 20),
                  if (category != null || difficulty != null || topic != null || exam != null || startDate != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => setState(() {
                          category = null; difficulty = null; topic = null; exam = null; startDate = null;
                        }),
                        child: TextStyle(color: AppColors.accent).toString() != "" ? Text("Reset Filters", style: TextStyle(color: AppColors.accent)) : Text("Reset"),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // GRID
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<DocumentSnapshot> docs = snapshot.data!.docs;

                if (_searchController.text.isNotEmpty) {
                  final s = _searchController.text.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name'] ?? '').toLowerCase().contains(s);
                  }).toList();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _currentCount != docs.length) {
                    setState(() => _currentCount = docs.length);
                  }
                });

                if (docs.isEmpty) return const Center(child: Text("No tests found."));

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisExtent: 140,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _CompactTestCard(
                      data: data,
                      onDelete: () => _confirmDelete(docs[index].id, data['name'] ?? 'test'),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // 3. Helper: Dropdown
  Widget _sidebarDropdown(String label, String? selected, List<String> values, Function(String?) onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected == null ? AppColors.background : AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected == null ? AppColors.border : AppColors.primaryBlue),
            ),
            child: DropdownButton<String>(
              value: selected,
              hint: Text("All $label", style: const TextStyle(fontSize: 14)),
              isExpanded: true,
              underline: const SizedBox(),
              items: values.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: onSelected,
            ),
          ),
        ],
      ),
    );
  }

  // 4. Helper: Delete Dialog
  Future<void> _confirmDelete(String id, String name) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Test?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.hard),
              child: const Text("Delete")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('tests').doc(id).delete();
    }
  }
}

// 5. Helper Card Widget
class _CompactTestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;

  const _CompactTestCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Color diffColor = AppColors.medium;
    if (data['difficulty'] == 'Easy') diffColor = AppColors.easy;
    if (data['difficulty'] == 'Hard') diffColor = AppColors.hard;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text((data['difficulty'] ?? '').toUpperCase(),
                  style: TextStyle(color: diffColor, fontSize: 9, fontWeight: FontWeight.bold)),
              InkWell(onTap: onDelete, child: Icon(Icons.delete_outline, color: AppColors.hard, size: 16)),
            ],
          ),
          const SizedBox(height: 6),
          Text(data['name'] ?? 'Untitled', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          Text(data['topic'] ?? 'General', maxLines: 1, style: TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
          const Spacer(),
          Row(
            children: [
              Icon(Icons.help_outline, size: 12, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text("${(data['questions'] as List?)?.length ?? 0} Q", style: const TextStyle(fontSize: 10)),
              const Spacer(),
              Icon(Icons.timer_outlined, size: 12, color: AppColors.secondaryText),
              const SizedBox(width: 4),
              Text("${data['durationMinutes'] ?? 0}m", style: const TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }
}