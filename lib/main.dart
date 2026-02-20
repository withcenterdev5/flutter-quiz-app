import 'package:flutter/material.dart';
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
/// [MaterialApp.router] consumes [appRouter] for declarative navigation.
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
      child: MaterialApp.router(
        title: 'Quiz App',
        theme: AppTheme.light,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}