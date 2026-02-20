import 'package:flutter/foundation.dart';
import 'package:quiz_app/quiz/domain/exceptions/quiz.exception.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';

// ── Sentinel ─────────────────────────────────────────────────────────────────

/// Sentinel implementation of [QuizRepository] assigned to [QuizProvider._repository]
/// at construction time — before [QuizProvider.updateRepository] is called by
/// [ChangeNotifierProxyProvider].
///
/// Both methods throw a descriptive [StateError] in debug **and** release
/// builds, making a misconfigured DI chain impossible to ignore. This
/// eliminates the `QuizRepository?` nullable field, all `!` operators, and
/// the debug-only `assert` that preceded this pattern.
///
/// The sentinel is private to this file — it is an implementation detail of
/// [QuizProvider] and must never be referenced externally.
class _NotInjectedRepository implements QuizRepository {
  const _NotInjectedRepository();

  static Never _fail(String caller) => throw StateError(
        'QuizProvider.$caller() was called before updateRepository(). '
        'Verify that ChangeNotifierProxyProvider<QuizRepository, QuizProvider> '
        'is registered correctly in main.dart.',
      );

  @override
  Future<List<Question>> getQuestions() => _fail('loadQuestions');

  @override
  Future<QuizResult> submitAnswers(
    List<Question> questions,
    Map<int, int> answers,
  ) =>
      _fail('submitAnswers');
}

// ── Provider ─────────────────────────────────────────────────────────────────

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
/// - Use `Selector<QuizProvider, bool>` on [allAnswered] for the
///   Submit button's enabled state.
/// - Use `Selector<QuizProvider, String?>` on [submitError] to trigger
///   a SnackBar when a submission attempt fails.
/// - Use `context.read<QuizProvider>()` inside all `onPressed` callbacks.
class QuizProvider extends ChangeNotifier {
  QuizProvider();

  // ── Private fields ───────────────────────────────────────────────────

  /// Starts as the [_NotInjectedRepository] sentinel and is replaced by
  /// [updateRepository] when the DI chain fires. Non-nullable by design —
  /// no `!` operators required anywhere in this class.
  QuizRepository _repository = const _NotInjectedRepository();

  QuizState _state = const QuizInitial();

  /// Cached question list — populated on [loadQuestions] success and
  /// cleared on [resetQuiz]. Stored separately from [QuizLoaded] so
  /// action methods can access it without pattern-matching the state.
  List<Question> _questions = const [];

  int _currentIndex = 0;

  /// Maps [Question.id] → the index the user selected. {1;0}
  final Map<int, int> _selectedAnswers = {};

  /// Holds the most recent submission error message, or `null` when
  /// no error has occurred / the error has been acknowledged.
  ///
  /// Set to non-null on [submitQuiz] failure; cleared at the start of
  /// every [submitQuiz] call. The screen watches this via a `Selector`
  /// and shows a SnackBar when it transitions from null → non-null.
  ///
  /// The session state stays at [QuizLoaded] on submit failure, so the
  /// user's answers are preserved and they can correct and retry without
  /// losing progress.
  String? _submitError;

  // ── Public state (read-only) ─────────────────────────────────────────

  /// The current sealed UI state. Screens `switch` on this value.
  QuizState get state => _state;

  /// Zero-based index of the question currently on screen.
  int get currentIndex => _currentIndex;

  /// Snapshot of all answers chosen so far.
  /// Keys are [Question.id]; values are the chosen option index.
  Map<int, int> get selectedAnswers => Map.unmodifiable(_selectedAnswers);

  /// The most recent submission failure message, or `null` when clear.
  ///
  /// The screen uses:
  /// ```dart
  /// Selector<QuizProvider, String?>(
  ///   selector: (_, p) => p.submitError,
  ///   builder: (context, error, _) {
  ///     if (error != null) {
  ///       WidgetsBinding.instance.addPostFrameCallback((_) {
  ///         ScaffoldMessenger.of(context).showSnackBar(
  ///           SnackBar(content: Text(error)),
  ///         );
  ///       });
  ///     }
  ///     return const SizedBox.shrink();
  ///   },
  /// )
  /// ```
  String? get submitError => _submitError;

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
  /// Replaces the [_NotInjectedRepository] sentinel with the real
  /// implementation. Subsequent calls to [loadQuestions] and [submitQuiz]
  /// use the injected repository directly — no null checks required.
  void updateRepository(QuizRepository repository) {
    _repository = repository;
  }

  // ── Actions ──────────────────────────────────────────────────────────

  /// Fetches questions from the repository and transitions:
  /// `QuizInitial | QuizError → QuizLoading → QuizLoaded | QuizError`
  ///
  /// Guards against duplicate calls — if already [QuizLoading], returns
  /// immediately without spawning a second concurrent request.
  Future<void> loadQuestions() async {
    if (_state is QuizLoading) return;

    _state = const QuizLoading();
    notifyListeners();

    try {
      final questions = await _repository.getQuestions();
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
  /// `QuizLoaded → QuizSubmitting → QuizSubmitted`
  ///
  /// **On failure** the state transitions back to `QuizLoaded(_questions)`,
  /// preserving all of the user's selected answers. [submitError] is set to
  /// the error message so the screen can surface it as a SnackBar without
  /// destroying the session. The user may correct and retry freely.
  ///
  /// Guards:
  /// - No-op if state is not [QuizLoaded].
  /// - No-op if not all questions are answered ([allAnswered] is `false`).
  Future<void> submitQuiz() async {
    if (_state is! QuizLoaded) return;
    if (!allAnswered) return;

    // Clear any stale error from a previous failed attempt before starting.
    _submitError = null;
    _state = const QuizSubmitting();
    notifyListeners();

    try {
      final result = await _repository.submitAnswers(
        _questions,
        Map.of(_selectedAnswers),
      );
      _state = QuizSubmitted(result);
    } on QuizException catch (e) {
      // ── Resilience: session stays alive on submit failure ─────────────
      // Transition back to QuizLoaded so _questions and _selectedAnswers
      // remain intact. The error is surfaced via submitError → SnackBar
      // in the screen layer, consistent with AGENTS.md non-destructive
      // error guidance.
      _submitError = e.message;
      _state = QuizLoaded(_questions);
    }

    notifyListeners();
  }

  /// Resets the entire session back to [QuizInitial].
  ///
  /// Clears questions, answers, navigation index, and any submit error
  /// so a retry starts from a completely clean slate.
  void resetQuiz() {
    _state = const QuizInitial();
    _questions = const [];
    _currentIndex = 0;
    _selectedAnswers.clear();
    _submitError = null;
    notifyListeners();
  }
}