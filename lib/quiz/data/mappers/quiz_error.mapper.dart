/// Maps raw exceptions thrown by [QuizService] into human-readable
/// strings for use by [QuizRepositoryImpl].
///
/// This mapper sits entirely inside the data layer and only ever sees
/// raw Dart / service exceptions. It never receives [QuizException] —
/// that type is what [QuizRepositoryImpl] throws *after* mapping.
///
/// Mapping is intentionally free of string parsing. Each branch returns
/// a literal string or delegates to [ArgumentError.message] /
/// [FormatException.message], both of which are typed fields.
abstract final class QuizErrorMapper {
  QuizErrorMapper._();

  /// Converts [error] into a user-facing message string.
  ///
  /// Dispatch order:
  /// 1. [FormatException]  — malformed data received from the service.
  /// 2. [ArgumentError]    — invalid data that slipped past [Question] validation.
  /// 3. Generic [Exception] — catch-all; returns a static fallback string.
  ///    No `.toString()` parsing is performed — [QuizException] carries
  ///    the message as a typed field, making string stripping unnecessary.
  /// 4. Unknown [Object]   — absolute fallback for non-Exception throws.
  static String map(Object error) {
    if (error is FormatException) {
      return 'The question data is malformed. Please try again.';
    }

    if (error is ArgumentError) {
      return 'Invalid question data was received. Please try again.';
    }

    if (error is Exception) {
      return 'An unexpected error occurred. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}