// lib/screens/view_tests_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ViewTestsScreen extends StatefulWidget {
  const ViewTestsScreen({super.key});

  @override
  State<ViewTestsScreen> createState() => _ViewTestsScreenState();
}

class _ViewTestsScreenState extends State<ViewTestsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedDifficulty;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _categories = ['All', 'General', 'Physics', 'Chemistry', 'Math', 'Biology'];
  final List<String> _difficulties = ['All', 'Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        // Trigger rebuild on search text change
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = null;
      _selectedDifficulty = null;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate!= null && _endDate!= null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) { // Custom builder for date picker theme
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Theme.of(context).primaryColor,
            colorScheme: ColorScheme.light(primary: Theme.of(context).primaryColor),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked!= null && (picked.start!= _startDate || picked.end!= _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end.add(const Duration(days: 1)).subtract(const Duration(microseconds: 1));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('tests').orderBy('createdAt', descending: true); // Default sort by newest first

    if (_selectedCategory!= null && _selectedCategory!= 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }
    if (_selectedDifficulty!= null && _selectedDifficulty!= 'All') {
      query = query.where('difficulty', isEqualTo: _selectedDifficulty);
    }
    if (_startDate!= null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: _startDate);
    }
    if (_endDate!= null) {
      query = query.where('createdAt', isLessThanOrEqualTo: _endDate);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0), // Increased padding
          child: ConstrainedBox( // Constrain filter section width
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                TextFormField( // Used TextFormField for consistent style
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by Name, Description, or Exam',
                    prefixIcon: const Icon(Icons.search, color: Colors.indigo), // Icon with theme color
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                        : null, // No suffix icon if empty
                  ),
                ),
                const SizedBox(height: 15), // Consistent spacing
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.subject),
                        ),
                        items: _categories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue == 'All'? null : newValue;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedDifficulty?? 'All',
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          prefixIcon: Icon(Icons.speed),
                        ),
                        items: _difficulties.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedDifficulty = newValue == 'All'? null : newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate == null
                              ? 'Select Date Range'
                              : '${DateFormat('MMM d, yyyy').format(_startDate!)} - ${DateFormat('MMM d, yyyy').format(_endDate!)}',
                          overflow: TextOverflow.ellipsis, // Prevent text overflow
                        ),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)), // Consistent button size
                      ),
                    ),
                    if (_startDate!= null)...[
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.redAccent), // Red close icon
                        tooltip: 'Clear Date Filter',
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                    ],
                    const SizedBox(width: 15),
                    ElevatedButton.icon( // Changed to icon button
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.filter_alt_off),
                      label: const Text('Clear Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600], // Muted color for clear
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: Center( // Center the list itself on very wide screens
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red)));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<DocumentSnapshot> filteredDocs = snapshot.data!.docs;

                  if (_searchController.text.isNotEmpty) {
                    final String lowerCaseSearch = _searchController.text.toLowerCase();
                    filteredDocs = filteredDocs.where((doc) {
                      final data = doc.data()! as Map<String, dynamic>;
                      final name = (data['name']?? '').toLowerCase();
                      final description = (data['description']?? '').toLowerCase();
                      final questions = data['questions'] as List<dynamic>?;
                      final askedInInQuestions = questions?.any((q) =>
                          (q['asked_in']?? '').toLowerCase().contains(lowerCaseSearch)
                      )?? false;

                      return name.contains(lowerCaseSearch) || description.contains(lowerCaseSearch) || askedInInQuestions;
                    }).toList();
                  }

                  if (filteredDocs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No tests found matching your criteria.', style: TextStyle(fontSize: 16)),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      var testDocument = filteredDocs[index];
                      Map<String, dynamic> data = testDocument.data()! as Map<String, dynamic>;

                      List<dynamic> questions = data['questions']?? [];
                      int questionCount = questions.length;

                      Set<String> askedInExams = {};
                      for (var q in questions) {
                        if (q['asked_in']!= null && q['asked_in'].toString().isNotEmpty) {
                          askedInExams.add(q['asked_in'].toString());
                        }
                      }
                      String askedInText = askedInExams.isNotEmpty? askedInExams.join(', ') : 'N/A';

                      return Card(
                        child: Padding( // Card already has margin from theme
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name']?? 'Untitled Test',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                data['description']?? 'No description',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Questions: $questionCount', style: Theme.of(context).textTheme.bodyMedium),
                                  Text('Duration: ${data['durationMinutes']?? 'N/A'} mins', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Difficulty: ${data['difficulty']?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                                  Text('Category: ${data['category']?? 'N/A'}', style: Theme.of(context).textTheme.bodyMedium),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Asked In: $askedInText', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 10), // Spacing before buttons
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.indigo),
                                      tooltip: 'Edit Test',
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Edit functionality coming soon!')),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                                      tooltip: 'Delete Test',
                                      onPressed: () async {
                                        bool? confirmDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
                                            content: Text('Are you sure you want to delete "${data['name']?? 'this test'}"?', style: Theme.of(context).textTheme.bodyLarge),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancel'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                                                child: const Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmDelete == true) {
                                          try {
                                            await FirebaseFirestore.instance.collection('tests').doc(testDocument.id).delete();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Test deleted successfully!')),
                                            );
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Failed to delete test: $e'), backgroundColor: Colors.red),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}