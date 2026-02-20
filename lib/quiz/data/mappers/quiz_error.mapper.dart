/// Maps raw [Exception] objects thrown by [QuizService] into
/// human-readable error strings for the presentation layer.
///
/// Centralising this logic here means [QuizRepositoryImpl] never
/// constructs error strings inline, and changing copy requires
/// touching exactly one file.
abstract final class QuizErrorMapper {
  QuizErrorMapper._();

  /// Converts [error] into a user-facing message.
  ///
  /// Dispatch order:
  /// 1. [FormatException] — malformed data from the service.
  /// 2. [ArgumentError]   — invalid data that slipped past validation.
  /// 3. Generic [Exception] — catch-all with the raw message surfaced.
  /// 4. Unknown [Object]  — absolute fallback for non-Exception throws.
  static String map(Object error) {
    if (error is FormatException) {
      return 'The question data is malformed. Please try again.';
    }

    if (error is ArgumentError) {
      return 'Invalid question data was received. Please try again.';
    }

    if (error is Exception) {
      final message = error.toString();
      // Strip the "Exception: " prefix Dart adds automatically so the
      // string shown to the user is clean.
      final cleaned = message.startsWith('Exception: ')
          ? message.substring('Exception: '.length)
          : message;
      return cleaned.isNotEmpty
          ? cleaned
          : 'An unexpected error occurred. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}