import 'package:quiz_app/quiz/data/services/quiz.service.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';

/// Concrete implementation of [QuizRepository].
///
/// Receives [QuizService] via constructor injection from [main.dart].
/// Full implementation added in Phase 2 (Task 2.3).
class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl(this._service);

  final QuizService _service;

  // ── Phase 2 stubs ────────────────────────────────────────────────────
  // Bodies are filled in Phase 2 (Tasks 2.1–2.3).
  // Declared here so the project compiles after the interface gains
  // concrete method signatures in Phase 1.

  @override
  Future<List<Question>> getQuestions() {
    // TODO(Phase 2): call _service.fetchQuestions() and map to Question list.
    throw UnimplementedError('getQuestions — implemented in Phase 2');
  }

  @override
  Future<QuizResult> submitAnswers(
    List<Question> questions,
    Map<int, int> answers,
  ) {
    // TODO(Phase 2): compute QuizResult in-memory.
    throw UnimplementedError('submitAnswers — implemented in Phase 2');
  }
}