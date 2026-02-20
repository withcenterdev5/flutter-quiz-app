/// Represents a single quiz question.
///
/// This is a pure domain model — zero Flutter dependencies.
///
/// Validation is enforced via [ArgumentError] so it fires in both
/// debug **and** release builds, unlike [assert] which is stripped
/// in release mode.
class Question {
  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctIndex,
  }) {
    if (options.length != 4) {
      throw ArgumentError.value(
        options.length,
        'options',
        'A Question must have exactly 4 options, got ${options.length}.',
      );
    }
    if (correctIndex < 0 || correctIndex > 3) {
      throw ArgumentError.value(
        correctIndex,
        'correctIndex',
        'correctIndex must be 0–3, got $correctIndex.',
      );
    }
  }

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