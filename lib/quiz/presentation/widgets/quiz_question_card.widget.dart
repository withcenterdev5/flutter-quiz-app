import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';

/// Displays the current question number badge and question text.
///
/// Uses `Selector<QuizProvider, (int, String)>` — a Dart Record selecting
/// `(displayIndex, questionText)`. This widget **only** rebuilds when the
/// user navigates to a different question. It is completely silent when the
/// user picks or changes an answer option.
///
/// Pure stateless widget — no logic, no direct `watch`.
class QuizQuestionCard extends StatelessWidget {
  const QuizQuestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<QuizProvider, ({int displayIndex, int total, String text})>(
      selector: (_, provider) {
        final state = provider.state;
        if (state is QuizLoaded && state.questions.isNotEmpty) {
          return (
            displayIndex: provider.currentIndex + 1,
            total: state.questions.length,
            text: state.questions[provider.currentIndex].text,
          );
        }
        return (displayIndex: 0, total: 0, text: '');
      },
      builder: (context, data, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Card(
          elevation: 0,
          color: colorScheme.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Question number badge ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question ${data.displayIndex} of ${data.total}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Question text ──────────────────────────────────────
                Text(
                  data.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}