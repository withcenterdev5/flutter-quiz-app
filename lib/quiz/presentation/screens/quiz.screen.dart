import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/core/constants/route_names.dart';
import 'package:quiz_app/core/widgets/error_view.widget.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';
import 'package:quiz_app/quiz/presentation/widgets/quiz_nav_bar.widget.dart';
import 'package:quiz_app/quiz/presentation/widgets/quiz_option_tile.widget.dart';
import 'package:quiz_app/quiz/presentation/widgets/quiz_progress_bar.widget.dart';
import 'package:quiz_app/quiz/presentation/widgets/quiz_question_card.widget.dart';
import 'package:quiz_app/quiz/presentation/widgets/quiz_shimmer.widget.dart';

/// Quiz question screen.
///
/// ## State handling
/// Uses a single `context.watch<QuizProvider>().state` at the root —
/// the **only** permitted `watch` call in this file. This drives a sealed
/// `switch` expression that exhaustively covers every [QuizState] subtype.
/// Dart's compiler enforces 100% coverage; unhandled states are a
/// compile error, not a runtime surprise.
///
/// ## Rebuild scope
/// - This screen rebuilds only when the top-level sealed state *type*
///   changes (e.g. Loading → Loaded, Loaded → Submitting).
/// - Inner sub-widgets (`QuizProgressBar`, `QuizQuestionCard`,
///   `QuizOptionTile`, `QuizNavBar`) each own their rebuild scope via
///   `Selector` or `Consumer`. They do **not** rebuild when this screen
///   rebuilds during the same `QuizLoaded` phase.
///
/// ## SnackBar
/// A zero-size `Selector` on [QuizProvider.submitError] surfaces API
/// submission failures as a [SnackBar] without rebuilding any visible UI.
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── The single permitted watch call ──────────────────────────────────
    final state = context.watch<QuizProvider>().state;

    return Scaffold(
      body: Stack(
        children: [
          // ── Sealed state switch ───────────────────────────────────────
          switch (state) {
            // Router guard will redirect away from QuizInitial in Phase 5.
            // Until then, render nothing so the screen is blank rather than
            // showing stale content.
            QuizInitial() => const SizedBox.shrink(),

            // Shimmer skeleton — visually matches the loaded layout.
            QuizLoading() => const SafeArea(child: QuizShimmerLoader()),

            // Error state — retry reloads questions from scratch.
            QuizError(:final message) => ErrorView(
                message: message,
                onRetry: () => context.read<QuizProvider>().loadQuestions(),
              ),

            // Active quiz — composed of isolated sub-widgets.
            QuizLoaded() => const _QuizLoadedBody(),

            // Full-screen submitting overlay — replaces the loaded body.
            QuizSubmitting() => const _SubmittingOverlay(),

            // Trigger navigation to the results screen; renders nothing.
            QuizSubmitted(:final result) => _NavigateToResults(result: result),
          },

          // ── Submit error SnackBar listener ────────────────────────────
          // Zero-size; placed in a Stack so it does not affect layout.
          // Fires when a submission attempt fails while preserving the
          // loaded state (user's answers are not lost).
          const _SubmitErrorListener(),
        ],
      ),
    );
  }
}

// ── Loaded body ─────────────────────────────────────────────────────────────

/// Composes all Selector-scoped sub-widgets for the active quiz state.
///
/// Private to this file — [QuizScreen] is the only entry point.
/// All children manage their own rebuild scopes; this widget itself is
/// `const` and never rebuilds once mounted during [QuizLoaded].
class _QuizLoadedBody extends StatelessWidget {
  const _QuizLoadedBody();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Progress bar (rebuilds on currentIndex change only) ──────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: const QuizProgressBar(),
          ),

          const SizedBox(height: 20),

          // ── Scrollable question + options area ───────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question card (rebuilds on question change only).
                  const QuizQuestionCard(),

                  const SizedBox(height: 24),

                  // Option tiles — each rebuilds only when its own
                  // selected state flips. Uses a Selector to get the
                  // current question by reference without re-rendering
                  // tiles when unrelated state changes.
                  Selector<QuizProvider, Question>(
                    selector: (_, provider) {
                      final s = provider.state as QuizLoaded;
                      return s.questions[provider.currentIndex];
                    },
                    builder: (context, question, _) {
                      return Column(
                        children: [
                          for (int i = 0; i < question.options.length; i++) ...[
                            QuizOptionTile(
                              question: question,
                              optionIndex: i,
                            ),
                            if (i < question.options.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // ── Bottom navigation bar ─────────────────────────────────────
          const Divider(height: 1),
          const QuizNavBar(),
        ],
      ),
    );
  }
}

// ── Submitting overlay ──────────────────────────────────────────────────────

/// Full-screen loading overlay displayed during [QuizSubmitting].
///
/// Replaces the entire loaded body so the user cannot interact with
/// the quiz while the submission is in flight. Uses
/// [CircularProgressIndicator] per AGENTS.md button loading rules —
/// this is a full-screen action gate, not a list/content load.
class _SubmittingOverlay extends StatelessWidget {
  const _SubmittingOverlay();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: colorScheme.primary,
          ),
          const SizedBox(height: 20),
          Text(
            'Submitting your answers…',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Navigate to results ─────────────────────────────────────────────────────

/// Triggers navigation to [RouteNames.results] carrying [result] as
/// `GoRouter` `extra`.
///
/// A [StatefulWidget] is required because `context.go` must **not** be
/// called inside `build`. `initState` → `addPostFrameCallback` defers
/// the navigation call safely to after the current frame is painted.
///
/// `.go` replaces the stack — the quiz screen must not remain reachable
/// via the back gesture after submission.
class _NavigateToResults extends StatefulWidget {
  const _NavigateToResults({required this.result});

  final QuizResult result;

  @override
  State<_NavigateToResults> createState() => _NavigateToResultsState();
}

class _NavigateToResultsState extends State<_NavigateToResults> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.go(RouteNames.results, extra: widget.result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Renders nothing — this widget exists solely to fire the navigation
    // side-effect. The flash is imperceptible; the callback fires before
    // the next frame.
    return const SizedBox.shrink();
  }
}

// ── Submit error SnackBar listener ──────────────────────────────────────────

/// Zero-size widget that watches [QuizProvider.submitError] and shows a
/// [SnackBar] when it transitions from `null` to a non-null message.
///
/// Kept separate from the main layout so the SnackBar trigger never
/// causes any visible subtree to rebuild.
///
/// [QuizProvider.submitError] is set on submission API failure while
/// the provider stays in [QuizLoaded] — this surfaces the error without
/// destroying the user's in-progress session.
class _SubmitErrorListener extends StatelessWidget {
  const _SubmitErrorListener();

  @override
  Widget build(BuildContext context) {
    return Selector<QuizProvider, String?>(
      selector: (_, provider) => provider.submitError,
      builder: (context, error, _) {
        if (error != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(error),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          });
        }
        return const SizedBox.shrink();
      },
    );
  }
}