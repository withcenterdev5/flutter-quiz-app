import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:quiz_app/core/router/app_router.dart';
import 'package:quiz_app/core/theme/app_theme.dart';
import 'package:quiz_app/quiz/data/repositories/quiz.repository_impl.dart';
import 'package:quiz_app/quiz/data/services/quiz.service.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';

void main() {
  runApp(const QuizApp());
}

/// Root widget.
///
/// Owns the [MultiProvider] tree that performs constructor-injection
/// top-down through the Clean Architecture layers:
///
///   [QuizService] ──► [QuizRepositoryImpl] ──► [QuizProvider]
///
/// The [GoRouter] instance is **not** created here — it is created by the
/// private [_AppRouter] widget which sits inside the [MultiProvider] subtree.
/// This is required because [createAppRouter] needs a direct reference to
/// the [QuizProvider] instance for its redirect guards and `refreshListenable`,
/// and [QuizProvider] does not exist until the [MultiProvider] tree is built.
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ── Data layer ─────────────────────────────────────────────────
        // Raw data service — no dependencies, created once.
        Provider<QuizService>(
          create: (_) => const QuizService(),
        ),

        // Repository implementation — receives [QuizService] via
        // [ProxyProvider]. The rest of the app depends on the
        // [QuizRepository] abstraction, not the concrete impl.
        ProxyProvider<QuizService, QuizRepository>(
          update: (_, service, __) => QuizRepositoryImpl(service),
        ),

        // ── Presentation layer ─────────────────────────────────────────
        // ViewModel — receives [QuizRepository] via
        // [ChangeNotifierProxyProvider] so Provider rebuilds widgets
        // correctly when the dependency graph changes.
        ChangeNotifierProxyProvider<QuizRepository, QuizProvider>(
          create: (_) => QuizProvider(),
          update: (_, repository, provider) {
            return provider!..updateRepository(repository);
          },
        ),
      ],

      // _AppRouter sits inside the MultiProvider subtree so it can
      // read QuizProvider during initState.
      child: const _AppRouter(),
    );
  }
}

/// Creates and owns the [GoRouter] instance for the lifetime of the app.
///
/// ## Why StatefulWidget
/// [GoRouter] must be disposed when it is no longer needed to release its
/// internal listeners and stream subscriptions. A [StatefulWidget] gives us
/// a reliable [dispose] hook that a [StatelessWidget] does not have.
///
/// ## Why this widget exists
/// [createAppRouter] requires a [QuizProvider] reference so it can:
/// - Pass it as `refreshListenable` (GoRouter re-evaluates redirects on
///   every [QuizProvider.notifyListeners] call).
/// - Read [QuizProvider.state] synchronously inside the `redirect` callback,
///   which runs outside the widget tree and cannot use [BuildContext].
///
/// `initState` is the correct place to call `context.read` for one-time
/// setup because it runs once after the first [build] and the widget is
/// guaranteed to be inside the [MultiProvider] subtree at that point.
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  // Non-nullable: assigned in initState before the first build completes.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // context.read is safe in initState — the widget is already mounted
    // inside the MultiProvider tree, so QuizProvider is guaranteed to exist.
    _router = createAppRouter(context.read<QuizProvider>());
  }

  @override
  void dispose() {
    // Release GoRouter's internal listeners and stream subscriptions.
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quiz App',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}