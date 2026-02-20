/// Raw data service for the quiz feature.
///
/// Acts as the in-memory question bank. In a real app this would call
/// an HTTP client or local database — swapping the implementation here
/// is the only change needed in the rest of the architecture.
///
/// [fetchQuestions] simulates network latency with [Future.delayed] so
/// the shimmer loading state is always exercised during development.
class QuizService {
  const QuizService();

  /// The hardcoded question bank.
  ///
  /// Keys per entry:
  /// - `id`           : unique int identifier
  /// - `text`         : the question string
  /// - `options`      : exactly 4 answer strings (A–D by index)
  /// - `correctIndex` : zero-based index of the correct option
  static const List<Map<String, dynamic>> _rawQuestions = [
    {
      'id': 1,
      'text': 'What is the primary programming language used to build Flutter apps?',
      'options': ['Kotlin', 'Swift', 'Dart', 'JavaScript'],
      'correctIndex': 2,
    },
    {
      'id': 2,
      'text': 'Which planet is known as the Red Planet?',
      'options': ['Venus', 'Mars', 'Jupiter', 'Saturn'],
      'correctIndex': 1,
    },
    {
      'id': 3,
      'text': 'In Flutter, which widget rebuilds its subtree when [ChangeNotifier] calls notifyListeners()?',
      'options': ['StatefulWidget', 'Consumer', 'InheritedWidget', 'Builder'],
      'correctIndex': 1,
    },
    {
      'id': 4,
      'text': 'Who painted the Mona Lisa?',
      'options': ['Michelangelo', 'Raphael', 'Caravaggio', 'Leonardo da Vinci'],
      'correctIndex': 3,
    },
    {
      'id': 5,
      'text': 'In Dart, what does the `late` keyword guarantee?',
      'options': [
        'The variable is always nullable',
        'The variable is initialised before its first use',
        'The variable is computed at compile time',
        'The variable cannot be reassigned',
      ],
      'correctIndex': 1,
    },
    {
      'id': 6,
      'text': 'How many bones are in the adult human body?',
      'options': ['196', '206', '216', '226'],
      'correctIndex': 1,
    },
    {
      'id': 7,
      'text': 'Which GoRouter method replaces the entire navigation stack?',
      'options': ['context.push()', 'context.pop()', 'context.go()', 'context.replace()'],
      'correctIndex': 2,
    },
    {
      'id': 8,
      'text': 'What is the chemical symbol for Gold?',
      'options': ['Go', 'Gd', 'Au', 'Ag'],
      'correctIndex': 2,
    },
    {
      'id': 9,
      'text': 'In Flutter\'s Provider package, which tool rebuilds only when a specific field changes?',
      'options': ['Consumer', 'Selector', 'ProxyProvider', 'ListenableBuilder'],
      'correctIndex': 1,
    },
    {
      'id': 10,
      'text': 'Which country is home to the Great Barrier Reef?',
      'options': ['Brazil', 'Indonesia', 'Philippines', 'Australia'],
      'correctIndex': 3,
    },
  ];

  /// Returns the raw question data after simulating an 800 ms async delay.
  ///
  /// The delay keeps the [QuizLoading] shimmer state consistently visible
  /// during development and testing. Remove or reduce it for production.
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return _rawQuestions;
  }
}