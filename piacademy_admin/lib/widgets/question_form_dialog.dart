// lib/widgets/question_form_dialog.dart

import 'package:flutter/material.dart';

class QuestionFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialQuestion; // For editing existing questions

  const QuestionFormDialog({super.key, this.initialQuestion});

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _textEnController;
  late TextEditingController _textTeController;
  late TextEditingController _askedInController; // <--- NEW: Asked in controller
  late List<TextEditingController> _optionsEnControllers;
  late List<TextEditingController> _optionsTeControllers;
  late TextEditingController _solutionEnController;
  late TextEditingController _solutionTeController;

  late String _questionType;
  late int _correctAnswerIndex;

  @override
  void initState() {
    super.initState();
    _questionType = widget.initialQuestion?['type']?? 'MCQ';
    _correctAnswerIndex = widget.initialQuestion?['correctAnswerIndex']?? 0;

    _textEnController = TextEditingController(text: widget.initialQuestion?['text_en']);
    _textTeController = TextEditingController(text: widget.initialQuestion?['text_te']);
    _askedInController = TextEditingController(text: widget.initialQuestion?['asked_in']); // <--- NEW: Initialize Asked in
    _solutionEnController = TextEditingController(text: widget.initialQuestion?['solution_en']);
    _solutionTeController = TextEditingController(text: widget.initialQuestion?['solution_te']);

    _optionsEnControllers = List.generate(4, (index) => TextEditingController());
    _optionsTeControllers = List.generate(4, (index) => TextEditingController());

    if (widget.initialQuestion!= null) {
      List<dynamic> initialOptionsEn = widget.initialQuestion!['options_en']?? [];
      List<dynamic> initialOptionsTe = widget.initialQuestion!['options_te']?? [];
      for (int i = 0; i < 4; i++) {
        if (i < initialOptionsEn.length) {
          _optionsEnControllers[i].text = initialOptionsEn[i].toString();
        }
        if (i < initialOptionsTe.length) {
          _optionsTeControllers[i].text = initialOptionsTe[i].toString();
        }
      }
    }
  }

  @override
  void dispose() {
    _textEnController.dispose();
    _textTeController.dispose();
    _askedInController.dispose(); // <--- NEW: Dispose Asked in controller
    _solutionEnController.dispose();
    _solutionTeController.dispose();
    for (var controller in _optionsEnControllers) {
      controller.dispose();
    }
    for (var controller in _optionsTeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'type': _questionType,
        'text_en': _textEnController.text,
        'text_te': _textTeController.text,
        'asked_in': _askedInController.text, // <--- NEW: Add Asked in to result
        'options_en': _optionsEnControllers.map((c) => c.text).toList(),
        'options_te': _optionsTeControllers.map((c) => c.text).toList(),
        'correctAnswerIndex': _correctAnswerIndex,
        'solution_en': _solutionEnController.text,
        'solution_te': _solutionTeController.text,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialQuestion == null? 'Add New Question' : 'Edit Question'),
      // <--- NEW: Constrain the dialog size for better web experience
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // Take 60% of screen width
        height: MediaQuery.of(context).size.height * 0.8, // Take 80% of screen height
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _textEnController,
                  decoration: const InputDecoration(labelText: 'Question Text (English)'),
                  maxLines: 2,
                  validator: (value) => value!.isEmpty? 'Enter English question' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _textTeController,
                  decoration: const InputDecoration(labelText: 'Question Text (Telugu)'),
                  maxLines: 2,
                  validator: (value) => value!.isEmpty? 'Enter Telugu question' : null,
                ),
                const SizedBox(height: 10),
                // <--- NEW: Asked In field
                TextFormField(
                  controller: _askedInController,
                  decoration: const InputDecoration(labelText: 'Asked In (e.g., SSC CGL 2023)'),
                  validator: (value) => value!.isEmpty? 'Enter where the question was asked' : null,
                ),
                const SizedBox(height: 20),
                const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswerIndex,
                          onChanged: (int? value) {
                            setState(() {
                              _correctAnswerIndex = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionsEnControllers[index],
                            decoration: InputDecoration(labelText: 'Option ${index + 1} (English)'),
                            validator: (value) => value!.isEmpty? 'Enter English option' : null,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: TextFormField(
                            controller: _optionsTeControllers[index],
                            decoration: InputDecoration(labelText: 'Option ${index + 1} (Telugu)'),
                            validator: (value) => value!.isEmpty? 'Enter Telugu option' : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _solutionEnController,
                  decoration: const InputDecoration(labelText: 'Solution (English)'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty? 'Enter English solution' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _solutionTeController,
                  decoration: const InputDecoration(labelText: 'Solution (Telugu)'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty? 'Enter Telugu solution' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveQuestion,
          child: const Text('Save Question'),
        ),
      ],
    );
  }
}