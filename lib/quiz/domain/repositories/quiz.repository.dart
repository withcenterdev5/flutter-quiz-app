import 'package:quiz_app/quiz/domain/exceptions/quiz.exception.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';

/// Abstract repository interface for the quiz feature.
///
/// Defines the contract between the domain and data layers.
/// The presentation layer and [QuizProvider] depend **only** on this
/// abstraction — never on [QuizRepositoryImpl] directly.
///
/// Concrete implementation: [QuizRepositoryImpl] (data layer).
abstract class QuizRepository {
  /// Fetches the ordered list of quiz questions.
  ///
  /// Throws [QuizException] on failure with a pre-mapped,
  /// user-friendly [QuizException.message].
  Future<List<Question>> getQuestions();

  /// Submits the user's answers and computes the [QuizResult].
  ///
  /// [questions] — the full list returned by [getQuestions].
  /// [answers]   — maps each [Question.id] to the user's chosen index.
  ///
  /// Throws [QuizException] on failure.
  Future<QuizResult> submitAnswers(
    List<Question> questions,
    Map<int, int> answers,
  );
}