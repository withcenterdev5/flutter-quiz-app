import 'package:flutter/material.dart';

/// Quiz question screen.
///
/// Full implementation (sealed state switch, Selector-scoped widgets)
/// added in Phase 4 (Task 4.8).
class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Quiz Screen — Phase 4')),
    );
  }
}