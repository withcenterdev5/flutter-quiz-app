import 'package:quiz_app/quiz/domain/models/question.model.dart';

/// Represents the outcome of a completed quiz session.
///
/// Computed in [QuizRepositoryImpl.submitAnswers] and passed to the
/// presentation layer as an immutable snapshot of the session.
///
/// This is a pure domain model — zero Flutter dependencies.
class QuizResult {
  const QuizResult({
    required this.questions,
    required this.selectedAnswers,
  });

  /// The full ordered list of questions that were presented.
  final List<Question> questions;

  /// Maps each [Question.id] to the index the user selected.
  ///
  /// A missing key means the user did not answer that question.
  final Map<int, int> selectedAnswers;

  /// Total number of questions in this session.
  int get total => questions.length;

  /// Number of questions answered correctly.
  ///
  /// A question is correct when [selectedAnswers][question.id]
  /// equals [Question.correctIndex].
  int get score => questions.fold(0, (count, question) {
        final chosen = selectedAnswers[question.id];
        return chosen == question.correctIndex ? count + 1 : count;
      });

  /// Number of questions answered incorrectly.
  int get incorrectCount => total - score;

  /// Percentage score expressed as a value between 0.0 and 1.0.
  double get percentage => total == 0 ? 0 : score / total;

  /// Whether the user answered a specific question correctly.
  bool isCorrect(Question question) =>
      selectedAnswers[question.id] == question.correctIndex;

  /// The answer string the user selected for a given question.
  /// Returns null if the question was not answered.
  String? selectedAnswerText(Question question) {
    final index = selectedAnswers[question.id];
    if (index == null) return null;
    return question.options[index];
  }

  @override
  String toString() => 'QuizResult(score: $score / $total)';
}