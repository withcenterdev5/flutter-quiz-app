import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';

/// Sealed state hierarchy for the quiz feature.
///
/// Every possible UI state is represented as a concrete subclass.
/// [QuizScreen] uses a `switch` expression against this type, which
/// the Dart compiler exhaustiveness-checks — unhandled states are a
/// compile error, not a runtime surprise.
///
/// State transition map:
/// ```
/// QuizInitial
///     └─► QuizLoading
///             ├─► QuizLoaded
///             │       └─► QuizSubmitting
///             │                ├─► QuizSubmitted
///             │                └─► QuizError
///             └─► QuizError
/// QuizError / QuizSubmitted
///     └─► QuizInitial  (via resetQuiz)
/// ```
sealed class QuizState {
  const QuizState();
}

/// The provider has been created but [QuizProvider.loadQuestions] has
/// not yet been called. The router guard redirects to `/` if the quiz
/// screen is reached in this state.
final class QuizInitial extends QuizState {
  const QuizInitial();
}

/// Questions are being fetched. The UI renders [QuizShimmerLoader].
final class QuizLoading extends QuizState {
  const QuizLoading();
}

/// Questions loaded successfully. The UI renders the active question.
final class QuizLoaded extends QuizState {
  const QuizLoaded(this.questions);

  /// The full ordered list of questions for this session.
  final List<Question> questions;
}

/// The submitted answers are being processed. The UI renders a
/// full-screen loading overlay with [CircularProgressIndicator].
final class QuizSubmitting extends QuizState {
  const QuizSubmitting();
}

/// Submission completed. The UI navigates to [ResultsScreen] and
/// passes [result] via GoRouter `extra`.
final class QuizSubmitted extends QuizState {
  const QuizSubmitted(this.result);

  /// The fully computed result for the completed session.
  final QuizResult result;
}

/// A recoverable error occurred during loading or submission.
/// The UI renders [ErrorView] with a retry callback.
final class QuizError extends QuizState {
  const QuizError(this.message);

  /// Human-readable message produced by [QuizErrorMapper] and
  /// carried through [QuizException].
  final String message;
}