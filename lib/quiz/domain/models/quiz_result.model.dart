import 'package:quiz_app/quiz/domain/models/question.model.dart';

/// Represents the outcome of a completed quiz session.
///
/// Computed in [QuizRepositoryImpl.submitAnswers] and passed to the
/// presentation layer as an immutable snapshot of the session.
///
/// This is a pure domain model — zero Flutter dependencies.
class QuizResult {
  QuizResult({
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
  /// Computed once on first access and cached for the lifetime of this
  /// object. Subsequent calls to [score], [incorrectCount], and
  /// [percentage] all read from this single cached value — no repeated
  /// iteration over [questions].
  late final int score = questions.fold(0, (count, question) {
    final chosen = selectedAnswers[question.id];
    return chosen == question.correctIndex ? count + 1 : count;
  });

  /// Number of questions answered incorrectly.
  int get incorrectCount => total - score;

  /// Percentage score expressed as a value between 0.0 and 1.0.
  double get percentage => total == 0 ? 0.0 : score / total;

  // ── Per-question helpers ─────────────────────────────────────────────

  /// Whether the user answered [question] at all.
  ///
  /// Always call this before [selectedAnswerText] to avoid null handling
  /// at the call site.
  bool wasAnswered(Question question) =>
      selectedAnswers.containsKey(question.id);

  /// Whether the user answered [question] correctly.
  bool isCorrect(Question question) =>
      selectedAnswers[question.id] == question.correctIndex;

  /// The answer string the user selected for [question].
  ///
  /// Returns `null` if the question was skipped (i.e., [wasAnswered]
  /// returns `false`). Callers must guard with [wasAnswered] rather
  /// than using the `!` operator on this return value.
  ///
  /// Example:
  /// ```dart
  /// if (result.wasAnswered(question)) {
  ///   Text(result.selectedAnswerText(question)!);
  /// } else {
  ///   Text('Not answered');
  /// }
  /// ```
  String? selectedAnswerText(Question question) {
    final index = selectedAnswers[question.id];
    if (index == null) return null;
    return question.options[index];
  }

  @override
  String toString() => 'QuizResult(score: $score / $total)';
}