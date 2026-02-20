import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';

/// Bottom navigation bar for the active quiz session.
///
/// Renders three logical zones in a single row:
/// - **Previous** — navigates back one question; hidden on the first question.
/// - **Counter** — "currentIndex + 1 / total" label (rebuilds only on
///   index change via the enclosing [Consumer]).
/// - **Next / Submit** — advances to the next question, or submits the quiz
///   when the user is on the last question.
///
/// ## Rebuild scope
/// The entire bar is wrapped in a `Consumer<QuizProvider>` so its rebuild
/// is isolated to this subtree. The question card and option tiles above it
/// are not affected when navigation state changes.
///
/// ## Button behaviour
/// All `onPressed` callbacks use `context.read` (never `watch`) per
/// AGENTS.md. The Submit button is disabled when [QuizProvider.allAnswered]
/// is `false` and shows a [CircularProgressIndicator] during [QuizSubmitting].
class QuizNavBar extends StatelessWidget {
  const QuizNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer scopes rebuilds to this widget subtree only.
    return Consumer<QuizProvider>(
      builder: (context, provider, _) {
        final state = provider.state;
        final isLoaded = state is QuizLoaded;
        final isSubmitting = state is QuizSubmitting;

        final total = isLoaded ? state.questions.length : 0;
        final currentDisplay = provider.currentIndex + 1;
        final isFirst = provider.currentIndex == 0;
        final isLast = provider.isLastQuestion;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                // ── Previous button ─────────────────────────────────────
                _PreviousButton(
                  isFirst: isFirst,
                  isLoaded: isLoaded,
                ),

                const SizedBox(width: 12),

                // ── Counter label ────────────────────────────────────────
                Expanded(
                  child: Text(
                    total > 0 ? '$currentDisplay / $total' : '—',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),

                const SizedBox(width: 12),

                // ── Next / Submit button ─────────────────────────────────
                isLast
                    ? _SubmitButton(
                        isSubmitting: isSubmitting,
                        isEnabled: isLoaded && provider.allAnswered,
                      )
                    : _NextButton(isLoaded: isLoaded),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Private sub-widgets ─────────────────────────────────────────────────────

/// Previous navigation button.
///
/// Hidden (zero-size) on the first question to maintain layout symmetry
/// with the Next/Submit button on the right.
class _PreviousButton extends StatelessWidget {
  const _PreviousButton({
    required this.isFirst,
    required this.isLoaded,
  });

  final bool isFirst;
  final bool isLoaded;

  @override
  Widget build(BuildContext context) {
    // Always occupies the same space so the counter stays centred.
    return SizedBox(
      width: 100,
      child: isFirst
          ? const SizedBox.shrink()
          : OutlinedButton.icon(
              onPressed: isLoaded
                  ? () => context.read<QuizProvider>().previousQuestion()
                  : null,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Prev'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
    );
  }
}

/// Next question navigation button.
class _NextButton extends StatelessWidget {
  const _NextButton({required this.isLoaded});

  final bool isLoaded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: FilledButton.icon(
        onPressed: isLoaded
            ? () => context.read<QuizProvider>().nextQuestion()
            : null,
        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
        label: const Text('Next'),
        // Icon after label for forward-direction affordance.
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}

/// Submit quiz button — shown only on the last question.
///
/// Uses two nested `Selector`s:
/// - One on [QuizProvider.allAnswered] for the disabled state.
/// - One on `state is QuizSubmitting` for the loading indicator.
///
/// Both are evaluated inside the [Consumer] above, so this widget takes
/// pre-computed booleans rather than re-selecting from the provider.
class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isSubmitting,
    required this.isEnabled,
  });

  final bool isSubmitting;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 100,
      child: FilledButton(
        // Disabled when !allAnswered or currently submitting.
        onPressed: (isEnabled && !isSubmitting)
            ? () => context.read<QuizProvider>().submitQuiz()
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          backgroundColor: colorScheme.tertiary,
          foregroundColor: colorScheme.onTertiary,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest,
        ),
        child: isSubmitting
            // ── AGENTS.md: CircularProgressIndicator for button loading ──
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colorScheme.onTertiary,
                ),
              )
            : const Text('Submit'),
      ),
    );
  }
}