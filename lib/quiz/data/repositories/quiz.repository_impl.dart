import 'package:quiz_app/quiz/data/mappers/quiz_error.mapper.dart';
import 'package:quiz_app/quiz/data/services/quiz.service.dart';
import 'package:quiz_app/quiz/domain/exceptions/quiz.exception.dart';

import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';

/// Concrete implementation of [QuizRepository].
///
/// Bridges [QuizService] (raw maps) with the domain layer ([Question],
/// [QuizResult]). This class is the single error boundary in the data
/// layer — every exception that leaves this class is a [QuizException]
/// with a pre-cleaned, user-friendly [QuizException.message].
///
/// Callers ([QuizProvider]) use `on QuizException catch (e)` — no
/// string parsing, no [Exception.toString] manipulation.
class QuizRepositoryImpl implements QuizRepository {
  const QuizRepositoryImpl(this._service);

  final QuizService _service;

  // ── QuizRepository interface ─────────────────────────────────────────

  @override
  Future<List<Question>> getQuestions() async {
    try {
      final rawList = await _service.fetchQuestions();
      return rawList.map(_mapToQuestion).toList(growable: false);
    } catch (e) {
      // Re-throw every raw exception as a typed QuizException so
      // QuizProvider receives one predictable type at the boundary.
      throw QuizException(QuizErrorMapper.map(e));
    }
  }

  @override
  Future<QuizResult> submitAnswers(
    List<Question> questions,
    Map<int, int> answers,
  ) async {
    try {
      return QuizResult(
        questions: questions,
        selectedAnswers: Map.unmodifiable(answers),
      );
    } catch (e) {
      throw QuizException(QuizErrorMapper.map(e));
    }
  }

  // ── Private mapper ───────────────────────────────────────────────────

  /// Maps a raw [Map<String, dynamic>] from [QuizService] to a [Question].
  ///
  /// Throws [FormatException] on type mismatches — caught upstream and
  /// converted to [QuizException] by [getQuestions].
  Question _mapToQuestion(Map<String, dynamic> raw) {
    try {
      return Question(
        id: raw['id'] as int,
        text: raw['text'] as String,
        options: List<String>.from(raw['options'] as List),
        correctIndex: raw['correctIndex'] as int,
      );
    } on TypeError catch (e) {
      throw FormatException(
        'Failed to parse question (id=${raw['id']}): $e',
      );
    }
  }
}