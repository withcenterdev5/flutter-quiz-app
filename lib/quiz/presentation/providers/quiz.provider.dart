import 'package:flutter/foundation.dart';
import 'package:quiz_app/quiz/domain/repositories/quiz.repository.dart';

/// ViewModel for the quiz feature.
///
/// Receives [QuizRepository] via [ChangeNotifierProxyProvider] in [main.dart].
/// Sealed state, action methods, and convenience getters are added
/// in Phase 3 (Tasks 3.1 & 3.2).
class QuizProvider extends ChangeNotifier {
  QuizProvider();

  /// Injected by [ChangeNotifierProxyProvider] on every dependency change.
  late QuizRepository _repository;

  /// Called by [ChangeNotifierProxyProvider.update] to inject the repository.
  void updateRepository(QuizRepository repository) {
    _repository = repository;
  }
}