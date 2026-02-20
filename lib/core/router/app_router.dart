import 'package:go_router/go_router.dart';
import 'package:quiz_app/core/constants/route_names.dart';
import 'package:quiz_app/core/screens/home_screen.dart';
import 'package:quiz_app/quiz/presentation/screens/quiz.screen.dart';
import 'package:quiz_app/quiz/presentation/screens/results.screen.dart';

/// Global [GoRouter] instance.
///
/// All navigation in the app must go through this router.
/// Route path constants live in [RouteNames].
///
/// **Redirect guards** are stubbed here and will be wired to
/// [QuizProvider] state in Phase 5.
final appRouter = GoRouter(
  initialLocation: RouteNames.home,
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RouteNames.quiz,
      builder: (context, state) => const QuizScreen(),
      // TODO(Phase 5): redirect to '/' if QuizProvider.state is QuizInitial.
    ),
    GoRoute(
      path: RouteNames.results,
      builder: (context, state) => const ResultsScreen(),
      // TODO(Phase 5): redirect to '/' if state.extra is null.
    ),
  ],
);