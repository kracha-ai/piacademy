class Question {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String solution;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.solution,
  });
}
List<Question> physicsQuestions = [

  Question(
    question: "A sound wave travels with a speed of 330 m/s and wavelength is 0.33 m. Find frequency.",
    options: ["10 Hz", "100 Hz", "300 Hz", "1000 Hz"],
    correctIndex: 3,
    solution: "Frequency = Speed / Wavelength = 330 / 0.33 = 1000 Hz",
  ),

  Question(
    question: "Which is example of uniform circular motion?",
    options: [
      "Bus moving on straight road",
      "Earth revolving around Sun",
      "Ball thrown upward",
      "Car braking"
    ],
    correctIndex: 1,
    solution: "Earth revolving around Sun is uniform circular motion.",
  ),

];
List<Question> chemistryQuestions = [

  Question(
    question: "Chlorine has isotopes Cl-35 (75%) and Cl-37 (25%). Average mass?",
    options: ["35.0 u", "36.0 u", "35.5 u", "37.0 u"],
    correctIndex: 2,
    solution: "(35×0.75) + (37×0.25) = 35.5 u",
  ),

];
List<Question> biologyQuestions = [

  Question(
    question: "Light dependent reaction occurs in?",
    options: ["Stroma", "Nucleus", "Thylakoid membrane", "Cytoplasm"],
    correctIndex: 2,
    solution: "Light reaction occurs in thylakoid membrane.",
  ),

];
