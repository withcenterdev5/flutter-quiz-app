import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Skeleton loader for the quiz question screen.
///
/// Visually mirrors [QuizQuestionCard] + four [QuizOptionTile]s so the
/// layout does not shift when real content arrives. Rendered exclusively
/// during the [QuizLoading] state.
///
/// Pure stateless widget — zero provider access.
class QuizShimmerLoader extends StatelessWidget {
  const QuizShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Shimmer base/highlight colours derived from the active theme so the
    // loader looks correct in both light and dark contexts.
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress bar skeleton ────────────────────────────────────
            _ShimmerBox(height: 6, width: double.infinity, radius: 3),

            const SizedBox(height: 28),

            // ── Question number badge skeleton ───────────────────────────
            _ShimmerBox(height: 28, width: 80, radius: 20),

            const SizedBox(height: 16),

            // ── Question card skeleton ───────────────────────────────────
            _ShimmerBox(height: 130, width: double.infinity, radius: 16),

            const SizedBox(height: 32),

            // ── Option tile skeletons (×4) ───────────────────────────────
            for (int i = 0; i < 4; i++) ...[
              _ShimmerBox(height: 64, width: double.infinity, radius: 12),
              if (i < 3) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Internal helper: a solid rounded rectangle shimmer block.
///
/// Kept private — callers interact only with [QuizShimmerLoader].
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.height,
    required this.width,
    required this.radius,
  });

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        // White is required — Shimmer.fromColors paints over it with the
        // base/highlight gradient. Any other colour will tint the shimmer.
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}