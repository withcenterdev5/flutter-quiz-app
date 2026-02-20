/// Central registry of all GoRouter route paths.
///
/// Every [context.go] and [context.push] call in the project must
/// reference these constants — never use raw string literals.
abstract final class RouteNames {
  /// Home screen — quiz entry point.
  static const String home = '/';

  /// Quiz question screen — active quiz session.
  static const String quiz = '/quiz';

  /// Results screen — post-submission grading view.
  static const String results = '/results';
}