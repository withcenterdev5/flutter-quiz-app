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
  /// Simulates a network/database call. The data layer introduces
  /// artificial latency to make the loading UX testable.
  ///
  /// Throws an [Exception] on failure; the implementation maps it
  /// to a user-friendly message via [QuizErrorMapper].
  Future<List<Question>> getQuestions();

  /// Submits the user's answers and computes the [QuizResult].
  ///
  /// [questions] — the full list returned by [getQuestions].
  /// [answers]   — maps each [Question.id] to the user's chosen index.
  ///
  /// Throws an [Exception] on failure.
  Future<QuizResult> submitAnswers(
    List<Question> questions,
    Map<int, int> answers,
  );
}