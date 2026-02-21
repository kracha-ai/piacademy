// lib/screens/create_test_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:collection/collection.dart'; // For ListEquality

import '../widgets/question_form_dialog.dart'; // Ensure this import path is correct for your setup

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({super.key});

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _totalQuestionsController = TextEditingController();

  String _difficulty = 'Easy';
  String _category = 'General';

  bool _isLoading = false;

  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];
  final List<String> _categories = ['General', 'Physics', 'Chemistry', 'Math', 'Biology'];

  final List<Map<String, dynamic>> _questions = []; // This list will now be saved directly

  // Function to add or edit a question
  Future<void> _addOrEditQuestion({Map<String, dynamic>? questionToEdit, int? index}) async {
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => QuestionFormDialog(initialQuestion: questionToEdit),
    );

    if (result!= null) {
      setState(() {
        if (index!= null) {
          _questions[index] = result;
        } else {
          _questions.add(result);
        }
      });
    }
  }

  // Function to pick and process a text file with more flexible parsing
  Future<void> _pickAndProcessFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
        allowMultiple: false,
        withData: true,
      );

      if (result!= null && result.files.single.bytes!= null) {
        final String fileContent = utf8.decode(result.files.single.bytes!);
        final List<String> lines = fileContent.split('\n');

        List<Map<String, dynamic>> parsedQuestions = [];
        Map<String, dynamic> currentQuestion = {'type': 'MCQ'}; // Initialize new question structure
        List<String> currentOptionsEn = List.filled(4, '');
        List<String> currentOptionsTe = List.filled(4, '');
        String? currentAnswerLetter;

        // Helper to finalize and add a question to the list
        void addCurrentQuestion() {
          if (currentQuestion.containsKey('text_en') && currentAnswerLetter!= null) {
            int? correctIndex = _parseAnswerLetter(currentAnswerLetter!);
            if (correctIndex!= null) {
              currentQuestion['options_en'] = List.from(currentOptionsEn); // Create new list from values
              currentQuestion['options_te'] = List.from(currentOptionsTe); // Create new list from values
              currentQuestion['correctAnswerIndex'] = correctIndex;
              parsedQuestions.add(currentQuestion);
            } else {
              _showSnackBar('Skipped a question due to invalid ANSWER letter: $currentAnswerLetter', Colors.red);
            }
          } else if (currentQuestion.isNotEmpty) {
            _showSnackBar('Skipped an incomplete question block.', Colors.red);
          }
          currentQuestion = {'type': 'MCQ'}; // Reset to a new question template
          currentOptionsEn = List.filled(4, '');
          currentOptionsTe = List.filled(4, '');
          currentAnswerLetter = null;
        }

        for (String line in lines) {
          String trimmedLine = line.trim();
          if (trimmedLine.isEmpty) {
            continue; // Ignore empty lines
          }

          // Check if this line signals the start of a NEW question
          if (trimmedLine.startsWith('Q_EN:') && currentQuestion.containsKey('text_en')) {
            addCurrentQuestion(); // If previous question was being built, add it now
          }

          if (trimmedLine.startsWith('Q_EN:')) {
            currentQuestion['text_en'] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('Q_TE:')) {
            currentQuestion['text_te'] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('ASKED_IN:')) {
            currentQuestion['asked_in'] = trimmedLine.substring(9).trim();
          } else if (trimmedLine.startsWith('A_EN:')) {
            currentOptionsEn[0] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('B_EN:')) {
            currentOptionsEn[1] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('C_EN:')) {
            currentOptionsEn[2] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('D_EN:')) {
            currentOptionsEn[3] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('A_TE:')) {
            currentOptionsTe[0] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('B_TE:')) {
            currentOptionsTe[1] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('C_TE:')) {
            currentOptionsTe[2] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('D_TE:')) {
            currentOptionsTe[3] = trimmedLine.substring(5).trim();
          } else if (trimmedLine.startsWith('ANSWER:')) {
            currentAnswerLetter = trimmedLine.substring(7).trim();
          } else if (trimmedLine.startsWith('SOLUTION_EN:')) {
            currentQuestion['solution_en'] = trimmedLine.substring(12).trim();
          } else if (trimmedLine.startsWith('SOLUTION_TE:')) {
            currentQuestion['solution_te'] = trimmedLine.substring(12).trim();
          }
        }

        // Add the very last question after the loop finishes
        addCurrentQuestion();

        setState(() {
          _questions.addAll(parsedQuestions);
          _showSnackBar('${parsedQuestions.length} questions parsed and added!', Colors.green);
        });
      } else {
        _showSnackBar('No file selected or file is empty.', Colors.red);
      }
    } catch (e) {
      print('Error picking or processing file: $e');
      _showSnackBar('Failed to pick or process file: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper to convert A,B,C,D to 0,1,2,3 index
  int? _parseAnswerLetter(String letter) {
    switch (letter.toUpperCase()) {
      case 'A': return 0;
      case 'B': return 1;
      case 'C': return 2;
      case 'D': return 3;
      default: return null;
    }
  }

  Future<void> _uploadTest() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill out all test details.', Colors.red);
      return;
    }
    if (_questions.isEmpty) {
      _showSnackBar('Please add at least one question.', Colors.red);
      return;
    }
    final listEquality = const ListEquality().equals;

    for (var q in _questions) {
      if (q['text_en'] == null || q['text_en'].isEmpty ||
          q['text_te'] == null || q['text_te'].isEmpty ||
          q['solution_en'] == null || q['solution_en'].isEmpty ||
          q['solution_te'] == null || q['solution_te'].isEmpty ||
          q['asked_in'] == null || q['asked_in'].isEmpty) {
        _showSnackBar('Please ensure all question fields, asked_in, and solutions are filled for all questions.', Colors.red);
        return;
      }
      if (q['correctAnswerIndex'] == null || q['correctAnswerIndex'] < 0 || q['correctAnswerIndex'] > 3) {
        _showSnackBar('Invalid correct answer index for one or more questions.', Colors.red);
        return;
      }
      if (listEquality(q['options_en'], List.filled(4, '')) || q['options_en'].any((opt) => opt == null || opt.isEmpty)) {
        _showSnackBar('Please ensure all English options are filled for all questions.', Colors.red);
        return;
      }
      if (listEquality(q['options_te'], List.filled(4, '')) || q['options_te'].any((opt) => opt == null || opt.isEmpty)) {
        _showSnackBar('Please ensure all Telugu options are filled for all questions.', Colors.red);
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('tests').add({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'durationMinutes': int.parse(_durationController.text),
        'totalQuestions': int.parse(_totalQuestionsController.text),
        'difficulty': _difficulty,
        'category': _category,
        'createdAt': FieldValue.serverTimestamp(),
        'questions': _questions,
      });

      _clearForm();
      _showSnackBar('Test uploaded successfully!', Colors.green);
    } catch (e) {
      print('Error uploading test: $e');
      _showSnackBar('Failed to upload test: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _totalQuestionsController.clear();
    setState(() {
      _difficulty = 'Easy';
      _category = 'General';
      _questions.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _totalQuestionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center( // Center content on wide screens
      child: ConstrainedBox( // Constrain max width for readability
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0), // Increased padding
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Test Details Section
                Text(
                  'Test Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Card( // Wrap test details in a Card
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Test Name (e.g., Physics Test 1)', prefixIcon: Icon(Icons.edit_note)),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a test name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _durationController,
                                decoration: const InputDecoration(labelText: 'Duration (minutes)', prefixIcon: Icon(Icons.timer)),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty || int.tryParse(value) == null) {
                                    return 'Valid number required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: TextFormField(
                                controller: _totalQuestionsController,
                                decoration: const InputDecoration(labelText: 'Total Questions', prefixIcon: Icon(Icons.format_list_numbered)),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty || int.tryParse(value) == null) {
                                    return 'Valid number required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _difficulty,
                                decoration: const InputDecoration(labelText: 'Difficulty', prefixIcon: Icon(Icons.speed)),
                                items: _difficulties.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _difficulty = newValue!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _category,
                                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.subject)),
                                items: _categories.map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _category = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Upload Questions Section
                Text(
                  'Upload Questions from File',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'Prepare a.txt file with questions formatted like the example below. Each question block should be complete.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isLoading? null : _pickAndProcessFile,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Text File (.txt)'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Theme.of(context).dividerColor),
                        Text(
                          'Alternatively, manually add questions below.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Manually Add Questions Section
                Text(
                  'Manually Add / Review Questions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),

                if (_questions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Center(
                      child: Text(
                        'No questions added yet. Use the "Upload File" button or click "Add Question" below.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ..._questions.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> question = entry.value;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ExpansionTile( // Using ExpansionTile for collapsible details
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      title: Text('Question ${index + 1}: ${question['text_en']?? 'N/A'}',
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Asked In: ${question['asked_in']?? 'N/A'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.indigo),
                            tooltip: 'Edit Question',
                            onPressed: () => _addOrEditQuestion(questionToEdit: question, index: index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            tooltip: 'Delete Question',
                            onPressed: () {
                              setState(() {
                                _questions.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                      childrenPadding: const EdgeInsets.all(16.0), // Padding for the expanded content
                      children: [
                        // Detailed content when expanded
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Question Text (Telugu):', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(question['text_te']?? 'N/A', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 10),

                            Text('Options (EN/TE):', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ...List.generate(4, (optionIndex) {
                              String optionEn = (question['options_en']!= null && question['options_en'].length > optionIndex)
                                  ? question['options_en'][optionIndex]
                                  : 'N/A';
                              String optionTe = (question['options_te']!= null && question['options_te'].length > optionIndex)
                                  ? question['options_te'][optionIndex]
                                  : 'N/A';
                              bool isCorrect = (question['correctAnswerIndex'] as int) == optionIndex;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  '${String.fromCharCode(65 + optionIndex)}. $optionEn / $optionTe ${isCorrect? '(Correct)' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isCorrect? Theme.of(context).primaryColor : Colors.black87,
                                    fontWeight: isCorrect? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 10),

                            Text('Solution (English):', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(question['solution_en']?? 'N/A', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 10),

                            Text('Solution (Telugu):', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                            Text(question['solution_te']?? 'N/A', style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addOrEditQuestion(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Final Upload Button
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _uploadTest,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    child: const Text('Upload Test to Firestore'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}