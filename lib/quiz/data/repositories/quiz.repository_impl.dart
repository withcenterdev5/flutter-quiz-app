import 'package:quiz_app/quiz/data/mappers/quiz_error.mapper.dart';
import 'package:quiz_app/quiz/data/services/quiz.service.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';

/// Concrete implementation of [QuizRepository].
///
/// Sits in the data layer and bridges [QuizService] (raw maps) with
/// the domain layer ([Question], [QuizResult]).
///
/// All [Exception]s are caught here and re-thrown as [Exception] with
/// a user-friendly message produced by [QuizErrorMapper], so the
/// [QuizProvider] only ever receives clean, displayable error strings.
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
      throw Exception(QuizErrorMapper.map(e));
    }
  }

  @override
  Future<QuizResult> submitAnswers(
    List<Question> questions,
    Map<int, int> answers,
  ) async {
    try {
      // QuizResult is computed entirely in-memory — no network call needed.
      // Wrapped in Future so the interface contract (async) is honoured
      // and the Provider can await it uniformly.
      return QuizResult(
        questions: questions,
        selectedAnswers: Map.unmodifiable(answers),
      );
    } catch (e) {
      throw Exception(QuizErrorMapper.map(e));
    }
  }

  // ── Private mapper ───────────────────────────────────────────────────

  /// Maps a raw [Map<String, dynamic>] from [QuizService] to a [Question].
  ///
  /// Throws [FormatException] if a required key is absent or has the
  /// wrong type — caught upstream by the [try/catch] in [getQuestions].
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