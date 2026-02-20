import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/quiz/domain/models/question.model.dart';
import 'package:quiz_app/quiz/presentation/providers/quiz.provider.dart';

/// Single answer option tile for a quiz question.
///
/// ## Rebuild isolation
/// Uses `Selector<QuizProvider, bool>` where the selected value is
/// `selectedAnswers[question.id] == optionIndex` — a single boolean.
///
/// Result: when the user taps an option, **only** the two affected tiles
/// rebuild (the previously selected tile deselects; the newly tapped tile
/// selects). All other tiles are untouched by the Provider notification.
///
/// This is deliberately more granular than the roadmap spec of
/// `Selector<QuizProvider, int?>` which would rebuild all four tiles on
/// every answer change. The `bool` approach is strictly O(1) per tap.
///
/// ## Usage
/// ```dart
/// for (int i = 0; i < question.options.length; i++)
///   QuizOptionTile(
///     question: question,
///     optionIndex: i,
///   )
/// ```
///
/// Interaction is handled internally via `context.read` — never `watch` —
/// as required by AGENTS.md.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.question,
    required this.optionIndex,
  });

  /// The parent question — used for its [Question.id] and option text.
  final Question question;

  /// Zero-based index of the option this tile represents (0 = A, 3 = D).
  final int optionIndex;

  /// Maps [optionIndex] to its letter label.
  static const _labels = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    return Selector<QuizProvider, bool>(
      // Equality is value-based (bool), so the builder only fires when
      // this tile's selected state actually flips.
      selector: (_, provider) =>
          provider.selectedAnswers[question.id] == optionIndex,
          // {0} = 3
      builder: (context, isSelected, _) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final tileColor = isSelected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerLow;

        final borderColor = isSelected
            ? colorScheme.secondary
            : colorScheme.outlineVariant;

        final labelBg =
            isSelected ? colorScheme.secondary : colorScheme.surfaceContainerHighest;

        final labelFg =
            isSelected ? colorScheme.onSecondary : colorScheme.onSurfaceVariant;

        final textColor = isSelected
            ? colorScheme.onSecondaryContainer
            : colorScheme.onSurface;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                context
                    .read<QuizProvider>()
                    .selectAnswer(question.id, optionIndex),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // ── Option letter badge ────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: labelBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _labels[optionIndex],
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: labelFg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ── Option text ────────────────────────────────────
                  Expanded(
                    child: Text(
                      question.options[optionIndex],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),

                  // ── Selected checkmark ─────────────────────────────
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}