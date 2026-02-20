import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/core/constants/route_names.dart';
import 'package:quiz_app/core/widgets/error_view.widget.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/domain/models/quiz_result.model.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';

/// Post-submission results and review screen.
///
/// Receives [QuizResult] via [GoRouterState.extra] — the screen owns its
/// data directly. **No provider reads are needed for display** since the
/// result is a fully self-contained snapshot of the completed session.
///
/// [QuizProvider] is accessed only in the Retry button to call [resetQuiz].
///
/// ## Layout
/// 1. **Score banner** — large `score / total` typography with a tinted
///    container whose colour reflects performance (good / average / poor).
/// 2. **Summary row** — correct ✅ and incorrect ❌ counts side by side.
/// 3. **Scrollable review list** — one [_ReviewCard] per question showing
///    the user's choice and the correct answer.
/// 4. **Retry button** — resets the provider and navigates back to `/`.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Extract result from router extra ──────────────────────────────
    final result = GoRouterState.of(context).extra as QuizResult?;

    // Guard: result should always be present; handle gracefully if not.
    if (result == null) {
      return Scaffold(
        body: ErrorView(
          message: 'Result data is missing. Please try the quiz again.',
          onRetry: () {
            context.read<QuizProvider>().resetQuiz();
            context.go(RouteNames.home);
          },
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Score banner ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _ScoreBanner(result: result),
            ),

            // ── Correct / Incorrect summary ─────────────────────────────
            SliverToBoxAdapter(
              child: _SummaryRow(result: result),
            ),

            // ── Per-question review header ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Question Review',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),

            // ── Review cards list ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList.separated(
                itemCount: result.questions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _ReviewCard(
                    question: result.questions[index],
                    result: result,
                    questionNumber: index + 1,
                  );
                },
              ),
            ),

            // ── Retry button ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                child: FilledButton.icon(
                  onPressed: () {
                    // 1. Reset the provider — clears all session state.
                    context.read<QuizProvider>().resetQuiz();
                    // 2. Navigate to home; .go replaces the stack so
                    //    results are not reachable via back.
                    context.go(RouteNames.home);
                  },
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Retry Quiz'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle:
                        Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score banner ────────────────────────────────────────────────────────────

/// Large, prominent score display at the top of the results screen.
///
/// Banner background colour reflects performance:
/// - ≥ 80 % → [ColorScheme.primaryContainer] (good)
/// - ≥ 50 % → [ColorScheme.tertiaryContainer] (average)
/// - < 50 % → [ColorScheme.errorContainer] (needs improvement)
class _ScoreBanner extends StatelessWidget {
  const _ScoreBanner({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bannerColor;
    final Color onBannerColor;
    final String message;

    if (result.percentage >= 0.8) {
      bannerColor = colorScheme.primaryContainer;
      onBannerColor = colorScheme.onPrimaryContainer;
      message = 'Excellent work! 🎉';
    } else if (result.percentage >= 0.5) {
      bannerColor = colorScheme.tertiaryContainer;
      onBannerColor = colorScheme.onTertiaryContainer;
      message = 'Not bad, keep practising!';
    } else {
      bannerColor = colorScheme.errorContainer;
      onBannerColor = colorScheme.onErrorContainer;
      message = 'Keep at it — you\'ve got this.';
    }

    return Container(
      width: double.infinity,
      color: bannerColor,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          // ── Score fraction ─────────────────────────────────────────
          Text(
            '${result.score} / ${result.total}',
            style: theme.textTheme.displayLarge?.copyWith(
              color: onBannerColor,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          // ── Percentage ─────────────────────────────────────────────
          Text(
            '${(result.percentage * 100).round()}%',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: onBannerColor.withOpacity(0.75),
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // ── Performance message ─────────────────────────────────────
          Text(
            message,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: onBannerColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary row ─────────────────────────────────────────────────────────────

/// Side-by-side correct / incorrect count chips.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.result});

  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              icon: Icons.check_circle_rounded,
              label: 'Correct',
              count: result.score,
              color: Colors.green.shade600,
              backgroundColor: Colors.green.shade50,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryChip(
              icon: Icons.cancel_rounded,
              label: 'Incorrect',
              count: result.incorrectCount,
              color: Theme.of(context).colorScheme.error,
              backgroundColor:
                  Theme.of(context).colorScheme.errorContainer.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Review card ─────────────────────────────────────────────────────────────

/// Per-question answer review card.
///
/// Shows the question text, the user's selected answer (colour-coded), and
/// the correct answer (always green). Multiple-choice options are **not**
/// shown — answer strings only, per the roadmap spec.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    super.key,
    required this.question,
    required this.result,
    required this.questionNumber,
  });

  final Question question;
  final QuizResult result;
  final int questionNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final wasAnswered = result.wasAnswered(question);
    final isCorrect = wasAnswered && result.isCorrect(question);
    final userAnswer = result.selectedAnswerText(question);

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect
              ? Colors.green.shade300
              : colorScheme.error.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Question number + text ─────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.text,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // ── User's answer ──────────────────────────────────────────
            _AnswerRow(
              label: 'Your answer',
              answer: wasAnswered ? userAnswer! : 'Not answered',
              icon: isCorrect
                  ? Icons.check_circle_rounded
                  : Icons.cancel_rounded,
              color: isCorrect ? Colors.green.shade600 : colorScheme.error,
            ),

            // Only show the correct answer row when the user was wrong
            // (avoids redundant repetition when they got it right).
            if (!isCorrect) ...[
              const SizedBox(height: 8),
              _AnswerRow(
                label: 'Correct answer',
                answer: question.correctAnswer,
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade600,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single answer label row inside [_ReviewCard].
class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    super.key,
    required this.label,
    required this.answer,
    required this.icon,
    required this.color,
  });

  final String label;
  final String answer;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                answer,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}