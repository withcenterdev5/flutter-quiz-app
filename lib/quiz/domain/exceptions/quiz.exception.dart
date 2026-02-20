/// A typed exception thrown at the [QuizRepository] boundary.
///
/// [QuizRepositoryImpl] is the only place that constructs this type.
/// All raw [Exception]s from [QuizService] are caught, mapped to a
/// human-readable [message] via [QuizErrorMapper], and re-thrown as
/// [QuizException] so every caller receives a single, clean type.
///
/// **Why a custom type instead of [Exception]?**
/// Rethrowing `Exception(string)` requires callers to call `.toString()`
/// and strip the `"Exception: "` prefix that Dart adds automatically —
/// brittle behaviour that breaks silently if the SDK ever changes the
/// prefix. [QuizException] carries [message] directly as a typed field,
/// so callers read `e.message` with no string parsing.
///
/// Usage in [QuizProvider]:
/// ```dart
/// try {
///   final questions = await _repository.getQuestions();
/// } on QuizException catch (e) {
///   state = QuizError(e.message);
/// }
/// ```
class QuizException implements Exception {
  const QuizException(this.message);

  /// Human-readable error string produced by [QuizErrorMapper].
  final String message;

  @override
  String toString() => 'QuizException: $message';
}