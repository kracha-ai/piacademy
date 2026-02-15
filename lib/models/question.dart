class Question {
  final String questionEn;
  final String questionTe;

  final List<String> optionsEn;
  final List<String> optionsTe;

  final int correctIndex;

  final String solutionEn;
  final String solutionTe;

  final String askedIn;

  Question({
    required this.questionEn,
    required this.questionTe,
    required this.optionsEn,
    required this.optionsTe,
    required this.correctIndex,
    required this.solutionEn,
    required this.solutionTe,
    required this.askedIn,
  });
}
