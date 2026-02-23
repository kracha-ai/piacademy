class Question {
  final String questionEn;
  final String questionTe;

  final List<String> optionsEn;
  final List<String> optionsTe;

  final int correctIndex;

  final String solutionEn;
  final String solutionTe;

  final String askedIn;
  final String? category; // <--- ADDED THIS LINE

  Question({
    required this.questionEn,
    required this.questionTe,
    required this.optionsEn,
    required this.optionsTe,
    required this.correctIndex,
    required this.solutionEn,
    required this.solutionTe,
    required this.askedIn,
    this.category, // <--- ADDED THIS LINE to the constructor
  });
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionEn: map['text_en'] as String? ?? '',
      questionTe: map['text_te'] as String? ?? '',
      optionsEn: List<String>.from(map['options_en'] as List? ?? []),
      optionsTe: List<String>.from(map['options_te'] as List? ?? []),
      correctIndex: map['correctAnswerIndex'] as int? ?? -1,
      solutionEn: map['solution_en'] as String? ?? '',
      solutionTe: map['solution_te'] as String? ?? '',
      askedIn: map['asked_in'] as String? ?? '',
      category: map['category'] as String?,
    );
  }
}