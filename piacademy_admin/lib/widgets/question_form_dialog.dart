import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialQuestion;

  const QuestionFormDialog({super.key, this.initialQuestion});

  @override
  State<QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<QuestionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _textEnController;
  late TextEditingController _textTeController;
  late TextEditingController _askedInController;
  late List<TextEditingController> _optionsEnControllers;
  late List<TextEditingController> _optionsTeControllers;
  late TextEditingController _solutionEnController;
  late TextEditingController _solutionTeController;

  late int _correctAnswerIndex;

  // Modern Blue Theme Colors
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color surfaceGrey = Color(0xFFF1F3F4);

  @override
  void initState() {
    super.initState();

    _correctAnswerIndex = widget.initialQuestion?['correctAnswerIndex'] ?? 0;

    _textEnController = TextEditingController(text: widget.initialQuestion?['text_en']);
    _textTeController = TextEditingController(text: widget.initialQuestion?['text_te']);
    _askedInController = TextEditingController(text: widget.initialQuestion?['asked_in']);
    _solutionEnController = TextEditingController(text: widget.initialQuestion?['solution_en']);
    _solutionTeController = TextEditingController(text: widget.initialQuestion?['solution_te']);

    _optionsEnControllers = List.generate(4, (i) =>
        TextEditingController(text: widget.initialQuestion?['options_en']?[i]?.toString()));

    _optionsTeControllers = List.generate(4, (i) =>
        TextEditingController(text: widget.initialQuestion?['options_te']?[i]?.toString()));
  }

  @override
  void dispose() {
    _textEnController.dispose();
    _textTeController.dispose();
    _askedInController.dispose();
    _solutionEnController.dispose();
    _solutionTeController.dispose();
    for (var c in _optionsEnControllers) c.dispose();
    for (var c in _optionsTeControllers) c.dispose();
    super.dispose();
  }

  InputDecoration _input(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: primaryBlue),
      labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
    );
  }

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop({
        'type': 'MCQ',
        'text_en': _textEnController.text.trim(),
        'text_te': _textTeController.text.trim(),
        'asked_in': _askedInController.text.trim(),
        'options_en': _optionsEnControllers.map((c) => c.text.trim()).toList(),
        'options_te': _optionsTeControllers.map((c) => c.text.trim()).toList(),
        'correctAnswerIndex': _correctAnswerIndex,
        'solution_en': _solutionEnController.text.trim(),
        'solution_te': _solutionTeController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFE8F0FE),
                    child: Icon(Icons.quiz, color: primaryBlue),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    widget.initialQuestion == null ? "Add New Question" : "Edit Question",
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF202124),
                    ),
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("Question Content"),
                      TextFormField(
                        controller: _textEnController,
                        maxLines: 2,
                        decoration: _input("English Question", Icons.language),
                        validator: (v) => v!.isEmpty ? "Enter English text" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _textTeController,
                        maxLines: 2,
                        decoration: _input("Telugu Question", Icons.translate),
                        validator: (v) => v!.isEmpty ? "Enter Telugu text" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _askedInController,
                        decoration: _input("Exam / Asked In", Icons.history_edu),
                      ),

                      const SizedBox(height: 32),
                      _sectionTitle("Options & Correct Answer"),
                      ...List.generate(4, (index) => _optionCard(index)),

                      const SizedBox(height: 32),
                      _sectionTitle("Explanations"),
                      TextFormField(
                        controller: _solutionEnController,
                        maxLines: 2,
                        decoration: _input("English Explanation", Icons.lightbulb_outline),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _solutionTeController,
                        maxLines: 2,
                        decoration: _input("Telugu Explanation", Icons.g_translate),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Save Question", style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: primaryBlue,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _optionCard(int index) {
    bool isSelected = _correctAnswerIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F7FF) : surfaceGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Radio<int>(
                value: index,
                groupValue: _correctAnswerIndex,
                activeColor: primaryBlue,
                onChanged: (v) => setState(() => _correctAnswerIndex = v!),
              ),
              Text(
                "OPTION ${String.fromCharCode(65 + index)}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryBlue : Colors.grey[800],
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check_circle, color: primaryBlue, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _optionsEnControllers[index],
            decoration: _input("English Option", Icons.abc),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _optionsTeControllers[index],
            decoration: _input("Telugu Option", Icons.translate),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
        ],
      ),
    );
  }
}