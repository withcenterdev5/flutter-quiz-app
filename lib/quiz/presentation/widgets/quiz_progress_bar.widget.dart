import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz_state.dart';

/// A fully isolated progress bar for the active quiz session.
///
/// Uses `Selector<QuizProvider, double>` to recompute only when the
/// progress ratio changes (i.e., when [QuizProvider.currentIndex] advances).
/// The question card and option tiles are **never** rebuilt as a side-effect
/// of this widget's selector.
///
/// Only meaningful during [QuizLoaded]; gracefully returns 0.0 otherwise.
class QuizProgressBar extends StatelessWidget {
  const QuizProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<QuizProvider, double>(
      // Progress = (currentIndex + 1) / totalQuestions.
      // The +1 makes the bar visually fill one step ahead so the first
      // question does not show 0 % complete.
      selector: (_, provider) {
        final state = provider.state;
        if (state is QuizLoaded && state.questions.isNotEmpty) {
          return (provider.currentIndex + 1) / state.questions.length;
        }
        return 0.0;
      },
      builder: (context, progress, _) {
        final colorScheme = Theme.of(context).colorScheme;

        return ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        );
      },
    );
  }
}