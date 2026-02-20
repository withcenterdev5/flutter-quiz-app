/// Represents a single quiz question.
///
/// This is a pure domain model — zero Flutter dependencies.
/// The [correctIndex] is the index into [options] that identifies
/// the correct answer and is intentionally kept internal to the domain;
/// the presentation layer never needs to know it directly until grading.
class Question {
  const Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  }) : assert(
          options.length == 4,
          'A Question must always have exactly 4 options.',
        ),
        assert(
          correctIndex >= 0 && correctIndex <= 3,
          'correctIndex must be a valid index into options (0–3).',
        );

  /// Unique identifier — used as the key in [QuizResult.selectedAnswers].
  final int id;

  /// The full question text displayed to the user.
  final String text;

  /// Exactly 4 answer choices labelled implicitly as A–D by their index.
  final List<String> options;

  /// Zero-based index of the correct answer within [options].
  final int correctIndex;

  /// Convenience getter — the correct answer string.
  String get correctAnswer => options[correctIndex];

  @override
  String toString() =>
      'Question(id: $id, text: $text, correctIndex: $correctIndex)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}