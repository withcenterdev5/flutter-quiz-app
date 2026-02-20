import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/core/constants/route_names.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';

/// Quiz entry-point screen.
///
/// Displays the app name, a brief description, and a **Start Quiz** button.
///
/// ## Navigation
/// Listens for [QuizLoaded] via a zero-size [Consumer] and calls
/// `context.go(RouteNames.quiz)` inside an `addPostFrameCallback`.
/// `.go` replaces the entire navigation stack so Home is not reachable
/// via the system back gesture during an active quiz session.
///
/// ## Loading UX
/// The Start Quiz button uses `Selector<QuizProvider, bool>` on
/// `state is QuizLoading`. Only the button rebuilds — the rest of the
/// screen is completely static.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Static body ─────────────────────────────────────────────
          _HomeBody(),

          // ── Navigation side-effect listener ─────────────────────────
          // Zero-size widget; exists purely to react to state transitions.
          // Placed in a Stack so it participates in the widget tree without
          // affecting layout.
          _QuizLoadedListener(),
        ],
      ),
    );
  }
}

// ── Static body ─────────────────────────────────────────────────────────────

/// Main body of [HomeScreen].
///
/// Intentionally a separate private widget so it never rebuilds when the
/// navigation listener re-renders on state changes.
class _HomeBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(flex: 2),

            // ── App icon / hero ────────────────────────────────────────
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz_rounded,
                  size: 52,
                  color: colorScheme.primary,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── App name ───────────────────────────────────────────────
            Text(
              'Quiz App',
              textAlign: TextAlign.center,
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            // ── Description ────────────────────────────────────────────
            Text(
              'Test your knowledge with a set of\nhand-crafted questions.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),

            const Spacer(flex: 2),

            // ── Start Quiz button (Selector-scoped loading) ─────────────
            Selector<QuizProvider, bool>(
              // Only rebuild the button when the loading state flips.
              selector: (_, provider) => provider.state is QuizLoading,
              builder: (context, isLoading, _) {
                return FilledButton(
                  // Disable while loading to prevent duplicate requests.
                  onPressed: isLoading
                      ? null
                      : () => context.read<QuizProvider>().loadQuestions(),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: isLoading
                      // ── AGENTS.md: CircularProgressIndicator for buttons ─
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Start Quiz'),
                );
              },
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ── Navigation listener ─────────────────────────────────────────────────────

/// Zero-size widget that watches [QuizProvider.state] and navigates to
/// [RouteNames.quiz] the moment [QuizLoaded] is emitted.
///
/// Using [Consumer] here (not [Selector]) because we need to act on the
/// full state object identity change, not a derived value. The widget
/// is invisible and outside the main layout tree, so its rebuilds have
/// no visual cost.
///
/// `addPostFrameCallback` defers `context.go` until after the current
/// build phase — calling navigation inside `build` directly is illegal
/// in Flutter.
class _QuizLoadedListener extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        if (provider.state is QuizLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Guard: only navigate if this widget is still in the tree.
            // Without this, a deferred callback after dispose would crash.
            if (context.mounted) {
              context.go(RouteNames.quiz);
            }
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}