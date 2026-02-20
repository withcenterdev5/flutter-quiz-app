import 'package:go_router/go_router.dart';
import 'package:quiz_app/core/constants/route_names.dart';
import 'package:quiz_app/core/screens/home_screen.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';
import 'package:quiz_app/quiz/presentation/screens/quiz.screen.dart';
import 'package:quiz_app/quiz/presentation/screens/results.screen.dart';

/// Factory that builds the app-wide [GoRouter] instance with redirect guards
/// wired to [QuizProvider] state.
///
/// ## Why a factory instead of a top-level `final`
/// GoRouter's `redirect` callback runs outside the widget tree — it has no
/// [BuildContext] and cannot call `context.read<QuizProvider>()`. The router
/// therefore needs a direct reference to the provider instance.
///
/// A top-level `final appRouter` is constructed before the Provider tree
/// exists, so the provider cannot be injected at that point. This factory is
/// called from `_AppRouter.initState()` (inside the `MultiProvider` subtree)
/// where `context.read<QuizProvider>()` is available.
///
/// ## refreshListenable
/// Passing [quizProvider] as `refreshListenable` tells GoRouter to
/// re-evaluate all `redirect` callbacks every time [QuizProvider]
/// calls `notifyListeners()`. This makes the guards reactive — e.g.,
/// when `resetQuiz()` transitions the state to [QuizInitial], GoRouter
/// immediately re-checks and redirects away from `/results` or `/quiz`
/// before `context.go('/')` even fires.
///
/// ## Navigation call map (project-wide)
///
/// | Call site                        | Method     | Reason                                                  |
/// |----------------------------------|------------|---------------------------------------------------------|
/// | `HomeScreen` → `/quiz`           | `.go()`    | Home must not remain on the back stack during a session |
/// | `QuizScreen` → `/results`        | `.go()`    | Quiz must not remain reachable via back after submit    |
/// | `ResultsScreen` → `/`            | `.go()`    | Results must not remain reachable after retry           |
/// | Redirect guard → `/`             | `return '/'` | Stack-safe; GoRouter replaces current location        |
GoRouter createAppRouter(QuizProvider quizProvider) {
  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: true,

    // GoRouter calls redirect after every navigation and after every
    // notifyListeners() from refreshListenable. Returning a path string
    // redirects; returning null allows the navigation to proceed.
    refreshListenable: quizProvider,

    redirect: (context, state) {
      final location = state.matchedLocation;

      // ── /quiz guard ───────────────────────────────────────────────────
      // Prevent direct URL access or back-stack resurrection when the
      // session has not been started. QuizInitial means loadQuestions()
      // has never been called — there is nothing to show on the quiz screen.
      //
      // States allowed on /quiz:
      //   QuizLoading | QuizLoaded | QuizSubmitting | QuizSubmitted | QuizError
      // States that trigger redirect:
      //   QuizInitial
      if (location == RouteNames.quiz) {
        if (quizProvider.state is QuizInitial) {
          return RouteNames.home;
        }
      }

      // ── /results guard ────────────────────────────────────────────────
      // Two independent conditions, both must pass to allow access:
      //
      // 1. Provider state is QuizSubmitted — the canonical source of truth.
      //    Catches: fresh app start, direct URL access, resetQuiz() firing
      //    refreshListenable before context.go('/') completes.
      //
      // 2. state.extra is QuizResult — secondary guard for direct URL /
      //    deep-link access where no extra is present.
      //
      // Note: GoRouter does NOT persist `extra` across refreshes triggered
      // by refreshListenable. Relying solely on `state.extra == null` would
      // therefore redirect away from /results on every provider notification
      // (e.g., every selectAnswer() call). The provider-state check is the
      // primary gate; the extra check is a belt-and-suspenders safety net.
      if (location == RouteNames.results) {
        if (quizProvider.state is! QuizSubmitted ||
            state.extra is! QuizResult) {
          return RouteNames.home;
        }
      }

      // No redirect — allow navigation to proceed.
      return null;
    },

    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.quiz,
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: RouteNames.results,
        builder: (context, state) => const ResultsScreen(),
      ),
    ],
  );
}