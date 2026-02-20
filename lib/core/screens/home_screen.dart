import 'package:flutter/material.dart';

/// Quiz entry-point screen.
///
/// Full implementation (Start Quiz button, Selector-scoped loading state)
/// added in Phase 4 (Task 4.7).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz App')),
      body: const Center(child: Text('Home Screen — Phase 4')),
    );
  }
}