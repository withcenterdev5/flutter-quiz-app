import 'package:quiz_app/quiz/data/services/quiz.service.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';

/// Concrete implementation of [QuizRepository].
///
/// Receives [QuizService] via constructor injection from [main.dart].
/// Full implementation added in Phase 2 (Task 2.3).
class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl(this._service);

  final QuizService _service;
}