import 'package:flutter/foundation.dart';
import 'package:quiz_app/quiz/domain/exceptions/quiz.exception.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';

/// ViewModel for the quiz feature.
///
/// Owns all quiz session state and exposes action methods that screens
/// call via `context.read<QuizProvider>()`. Screens are purely passive —
/// they never compute anything themselves.
///
/// Injected into the widget tree via [ChangeNotifierProxyProvider]
/// in `main.dart`. [updateRepository] is called by the proxy on every
/// dependency rebuild.
///
/// ## Selector / Consumer guidance
/// - Use `Selector<QuizProvider, QuizState>` at the screen root for the
///   sealed state `switch`.
/// - Use `Selector<QuizProvider, int>` on [currentIndex] for the
///   progress bar and question card.
/// - Use `Selector<QuizProvider, int?>` on `selectedAnswers[id]` for
///   individual option tiles.
/// - Use `context.read<QuizProvider>()` inside all `onPressed` callbacks.
class QuizProvider extends ChangeNotifier {
  QuizProvider();

  // ── Private fields ───────────────────────────────────────────────────

  QuizRepository? _repository;

  QuizState _state = const QuizInitial();

  /// Cached question list — populated on [loadQuestions] success and
  /// cleared on [resetQuiz]. Stored separately from [QuizLoaded] so
  /// action methods can access it without pattern-matching the state.
  List<Question> _questions = const [];

  int _currentIndex = 0;

  /// Maps [Question.id] → the index the user selected.
  final Map<int, int> _selectedAnswers = {};

  // ── Public state (read-only) ─────────────────────────────────────────

  /// The current sealed UI state. Screens `switch` on this value.
  QuizState get state => _state;

  /// Zero-based index of the question currently on screen.
  int get currentIndex => _currentIndex;

  /// Snapshot of all answers chosen so far.
  /// Keys are [Question.id]; values are the chosen option index.
  Map<int, int> get selectedAnswers => Map.unmodifiable(_selectedAnswers);

  // ── Convenience getters ──────────────────────────────────────────────

  /// `true` when the user is on the final question.
  ///
  /// Safe to call in any state — returns `false` when [_questions] is empty.
  bool get isLastQuestion =>
      _questions.isNotEmpty && _currentIndex == _questions.length - 1;

  /// `true` when the current question has a recorded answer.
  ///
  /// Safe to call in any state — returns `false` when [_questions] is empty.
  bool get hasAnsweredCurrent {
    if (_questions.isEmpty) return false;
    return _selectedAnswers.containsKey(_questions[_currentIndex].id);
  }

  /// `true` when every question in the session has been answered.
  ///
  /// Used by [QuizNavBar]'s `Selector` to enable/disable the Submit button.
  bool get allAnswered =>
      _questions.isNotEmpty &&
      _selectedAnswers.length == _questions.length;

  // ── DI wiring ────────────────────────────────────────────────────────

  /// Called by [ChangeNotifierProxyProvider.update] to inject the
  /// repository after the widget tree is built.
  ///
  /// Throws [StateError] if called with a null repository, making a
  /// misconfigured DI chain fail loudly at startup rather than silently
  /// at the first user action.
  void updateRepository(QuizRepository repository) {
    _repository = repository;
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Fetches questions from the repository and transitions:
  /// `QuizInitial | QuizError → QuizLoading → QuizLoaded | QuizError`
  ///
  /// Guards against duplicate calls — if already [QuizLoading], returns
  /// immediately without spawning a second request.
  Future<void> loadQuestions() async {
    assert(_repository != null, 'QuizProvider: repository was not injected.');
    if (_state is QuizLoading) return;

    _state = const QuizLoading();
    notifyListeners();

    try {
      final questions = await _repository!.getQuestions();
      _questions = questions;
      _currentIndex = 0;
      _selectedAnswers.clear();
      _state = QuizLoaded(questions);
    } on QuizException catch (e) {
      _state = QuizError(e.message);
    }

    notifyListeners();
  }

  /// Records the user's answer for [questionId] and notifies listeners.
  ///
  /// Overwrites any previous answer for the same question — changing
  /// your mind before submitting is allowed.
  ///
  /// No-op if the current state is not [QuizLoaded].
  void selectAnswer(int questionId, int chosenIndex) {
    if (_state is! QuizLoaded) return;
    _selectedAnswers[questionId] = chosenIndex;
    notifyListeners();
  }

  /// Advances to the next question.
  ///
  /// No-op if already on the last question or state is not [QuizLoaded].
  void nextQuestion() {
    if (_state is! QuizLoaded) return;
    if (_currentIndex >= _questions.length - 1) return;
    _currentIndex++;
    notifyListeners();
  }

  /// Returns to the previous question.
  ///
  /// No-op if already on the first question or state is not [QuizLoaded].
  void previousQuestion() {
    if (_state is! QuizLoaded) return;
    if (_currentIndex <= 0) return;
    _currentIndex--;
    notifyListeners();
  }

  /// Submits the session answers and transitions:
  /// `QuizLoaded → QuizSubmitting → QuizSubmitted | QuizError`
  ///
  /// Guards:
  /// - No-op if state is not [QuizLoaded].
  /// - No-op if not all questions are answered ([allAnswered] is false).
  ///
  /// On submission error the state transitions to [QuizError] so the
  /// [ErrorView] retry path leads back through [loadQuestions].
  Future<void> submitQuiz() async {
    assert(_repository != null, 'QuizProvider: repository was not injected.');
    if (_state is! QuizLoaded) return;
    if (!allAnswered) return;

    _state = const QuizSubmitting();
    notifyListeners();

    try {
      final result = await _repository!.submitAnswers(
        _questions,
        Map.of(_selectedAnswers),
      );
      _state = QuizSubmitted(result);
    } on QuizException catch (e) {
      _state = QuizError(e.message);
    }

    notifyListeners();
  }

  /// Resets the entire session back to [QuizInitial].
  ///
  /// Clears questions, answers, and navigation index so a retry
  /// starts from a completely clean slate.
  void resetQuiz() {
    _state = const QuizInitial();
    _questions = const [];
    _currentIndex = 0;
    _selectedAnswers.clear();
    notifyListeners();
  }
}