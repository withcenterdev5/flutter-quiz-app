# ROADMAP.md — quiz_app

> **Legend:** `[ ]` = Pending · `[x]` = Done · `[~]` = In Progress
> Update this file after every completed task or session. Never delete completed phases.

---

## Phase 0 — Project Bootstrap & Configuration
> Goal: Confirm the project compiles, dependencies are wired, and global infrastructure is in place.

### 0.1 Dependencies
- [ ] Verify `pubspec.yaml` includes: `provider`, `go_router`, `shimmer`, `google_fonts`
- [ ] Run `flutter pub get` and confirm zero errors

### 0.2 Theme
- [ ] Define `AppTheme` in `core/theme/app_theme.dart` using **Material Design 3**
  - Light color scheme using `ColorScheme.fromSeed`
  - Apply `GoogleFonts` text theme globally
- [ ] Wire `AppTheme.light` into `MaterialApp.router`

### 0.3 Global Routing Shell
- [ ] Create `core/router/app_router.dart` with `GoRouter` instance
- [ ] Define named route constants in `core/constants/route_names.dart`
  - `/` → Home Screen
  - `/quiz` → Quiz Question Screen (question index via `extra` or path param)
  - `/results` → Results Screen
- [ ] Wire router into `MaterialApp.router` in `main.dart`

### 0.4 Global Widgets
- [ ] Confirm `core/widgets/error_view.widget.dart` is implemented and reusable

### 0.5 Dependency Injection
- [ ] Register `QuizService`, `QuizRepositoryImpl`, and `QuizProvider` via `MultiProvider` / `ChangeNotifierProxyProvider` in `main.dart`

---

## Phase 1 — Domain Layer
> Goal: Define the business contracts. Zero Flutter dependencies.

### 1.1 Models (`quiz/domain/models/`)
- [ ] **`question.model.dart`** — `Question`
  ```
  id          : int
  text        : String
  options     : List<String>      // 4 labelled choices (A–D)
  correctIndex: int               // index into options
  ```
- [ ] **`quiz_result.model.dart`** — `QuizResult`
  ```
  questions       : List<Question>
  selectedAnswers : Map<int, int>   // questionId → chosen index
  score           : int             // computed getter
  ```

### 1.2 Repository Interface (`quiz/domain/repositories/`)
- [ ] **`quiz.repository.dart`** — `abstract class QuizRepository`
  - `Future<List<Question>> getQuestions()`
  - `Future<QuizResult> submitAnswers(List<Question>, Map<int,int> answers)`

---

## Phase 2 — Data Layer
> Goal: Implement the repository interface with in-memory mock data. No database.

### 2.1 Mock Service (`quiz/data/services/`)
- [ ] **`quiz.service.dart`** — `QuizService`
  - Holds a `static const List<Map<String, dynamic>> _rawQuestions` with **10 hardcoded questions**
  - Each question has: `id`, `text`, `options` (4 choices), `correctIndex`
  - Sample topics: general knowledge / Flutter trivia (mix to keep it interesting)
  - `Future<List<Map<String,dynamic>>> fetchQuestions()` — simulates async with `Future.delayed(800ms)`

### 2.2 Error Mapper (`quiz/data/mappers/`)
- [ ] **`quiz_error.mapper.dart`** — `QuizErrorMapper`
  - Converts raw `Exception` → human-readable `String` message
  - Handles: generic `Exception`, `FormatException`, unknown fallback

### 2.3 Repository Implementation (`quiz/data/repositories/`)
- [ ] **`quiz.repository_impl.dart`** — `QuizRepositoryImpl implements QuizRepository`
  - Calls `QuizService.fetchQuestions()`, maps raw maps → `Question` domain models
  - Wraps calls in `try/catch`, maps errors via `QuizErrorMapper`
  - `submitAnswers` computes `QuizResult` in-memory and returns it

---

## Phase 3 — Presentation Layer: State & Provider
> Goal: Define sealed UI states and the ChangeNotifier that drives every screen.

### 3.1 Sealed States (`quiz/presentation/providers/`)
- [ ] **`quiz_state.dart`** — Sealed class hierarchy
  ```dart
  sealed class QuizState {}
  class QuizInitial   extends QuizState {}
  class QuizLoading   extends QuizState {}
  class QuizLoaded    extends QuizState { final List<Question> questions; }
  class QuizError     extends QuizState { final String message; }
  class QuizSubmitting extends QuizState {}
  class QuizSubmitted  extends QuizState { final QuizResult result; }
  ```

### 3.2 Provider (`quiz/presentation/providers/`)
- [ ] **`quiz.provider.dart`** — `QuizProvider extends ChangeNotifier`
  - State: `QuizState state`, `int currentIndex`, `Map<int,int> selectedAnswers`
  - `loadQuestions()` → transitions: `Initial → Loading → Loaded | Error`
  - `selectAnswer(int questionId, int chosenIndex)` → saves to `selectedAnswers`, calls `notifyListeners()`
  - `nextQuestion()` / `previousQuestion()` → increments/decrements `currentIndex`
  - `submitQuiz()` → transitions: `Loaded → Submitting → Submitted | Error`
  - `resetQuiz()` → clears all state back to `Initial`
  - Expose `bool isLastQuestion` and `bool hasAnsweredCurrent` convenience getters

---

## Phase 4 — Presentation Layer: Screens & Widgets
> Goal: Build all three screens using switch expressions against sealed states. Screens are passive.

### 4.1 Shared / Core Widgets
- [ ] **`core/widgets/error_view.widget.dart`** — Accepts `message` + optional `onRetry` callback *(confirm exists)*

### 4.2 Quiz Shimmer Widget (`quiz/presentation/widgets/`)
- [ ] **`quiz_shimmer.widget.dart`** — `QuizShimmerLoader`
  - Mimics the question card + 4 option tiles layout
  - Uses `shimmer` package; must visually match `QuizQuestionCard`

### 4.3 Question Card Widget (`quiz/presentation/widgets/`)
- [ ] **`quiz_question_card.widget.dart`** — `QuizQuestionCard`
  - Displays: question number badge, question text, progress indicator (`currentIndex / total`)
  - Stateless; receives data via constructor

### 4.4 Option Tile Widget (`quiz/presentation/widgets/`)
- [ ] **`quiz_option_tile.widget.dart`** — `QuizOptionTile`
  - Displays one answer option; highlights selected state
  - `onTap` callback propagates selection up to screen → provider

### 4.5 Home Screen (`core/screens/home_screen.dart`)
- [ ] Display app name, brief description, and **"Start Quiz"** button
- [ ] On tap: call `provider.loadQuestions()` then navigate to `/quiz`
- [ ] Button shows `CircularProgressIndicator` while `QuizLoading`

### 4.6 Quiz Question Screen (`quiz/presentation/screens/quiz.screen.dart`)
- [ ] Driven entirely by `QuizProvider` via `context.watch`
- [ ] `switch (state)` handles all sealed states:
  - `QuizInitial` → redirect back to Home (guard)
  - `QuizLoading` → `QuizShimmerLoader`
  - `QuizError`   → `ErrorView(message, onRetry: provider.loadQuestions)`
  - `QuizLoaded`  → renders `QuizQuestionCard` + 4 `QuizOptionTile`s for `questions[currentIndex]`
  - `QuizSubmitting` → full-screen loading with `CircularProgressIndicator`
  - `QuizSubmitted`  → auto-navigate to `/results` (via `GoRouter`)
- [ ] Bottom bar:
  - **Previous** button (disabled on first question)
  - Question counter label (`3 / 10`)
  - **Next** button (disabled if current question unanswered)
  - **Submit** button replaces **Next** on the last question
    - Disabled until all 10 questions are answered
    - Shows `CircularProgressIndicator` while `QuizSubmitting`
- [ ] Show `SnackBar` warning if user attempts to submit with unanswered questions

### 4.7 Results Screen (`quiz/presentation/screens/results.screen.dart`)
- [ ] Receives `QuizResult` via GoRouter `extra`
- [ ] Displays:
  - **Score banner** — `7 / 10` in large, prominent typography
  - **Summary chips** — Correct ✅ / Incorrect ❌ counts
  - **Scrollable review list** — one card per question showing:
    - Question text
    - User's chosen answer (highlighted green if correct, red if wrong)
    - Correct answer label (always shown in green)
    - No multiple-choice options visible — just the answer strings
- [ ] **"Retry Quiz"** button → calls `provider.resetQuiz()` and navigates back to `/`

---

## Phase 5 — Routing & Navigation
> Goal: Wire GoRouter so navigation is declarative and state-safe.

- [ ] Route `/` → `HomeScreen`
- [ ] Route `/quiz` → `QuizScreen`
  - Guard: if `QuizProvider.state` is `QuizInitial`, redirect to `/`
- [ ] Route `/results` → `ResultsScreen`
  - Receives `QuizResult` via `GoRouterState.extra`
  - Guard: if `extra` is null, redirect to `/`
- [ ] `QuizProvider` triggers navigation imperatively inside `submitQuiz()` success using a `NavigatorKey` or a GoRouter `go()` call passed as a callback from the screen's listener pattern

---

## Phase 6 — Polish & Production Readiness
> Goal: Ensure UX is solid and the codebase is clean.

### 6.1 UX Polish
- [ ] Add a **progress bar** (`LinearProgressIndicator`) at the top of `QuizScreen` showing completion percentage
- [ ] Animate option selection (e.g., scale + color transition via `AnimatedContainer`)
- [ ] Add a confirmation `showDialog` when the user presses the system back button mid-quiz
  - "Are you sure? Your progress will be lost."
  - Actions: **Continue Quiz** / **Exit**

### 6.2 Accessibility & Resilience
- [ ] All interactive widgets have `Semantics` labels
- [ ] `QuizProvider.resetQuiz()` fully clears state (no stale references)
- [ ] Test navigation guards: direct URL access to `/results` without data redirects correctly

### 6.3 Code Quality
- [ ] All public classes and methods documented with `///` DartDocs
- [ ] No raw `print()` statements in production code
- [ ] All `const` constructors applied wherever possible
- [ ] Run `flutter analyze` with zero warnings

---

## Decisions & Notes

| Date | Decision | Rationale |
|------|----------|-----------|
| — | `QuizResult` is computed in `QuizRepositoryImpl.submitAnswers`, not in the Provider | Keeps the Provider a thin orchestrator; business logic stays in the domain/data boundary |
| — | Navigation to `/results` is triggered from the Screen (listener on state), not from inside the Provider | Providers must not hold `BuildContext`; the screen observes state changes and calls `context.go()` |
| — | `selectedAnswers` uses `Map<int, int>` keyed by `question.id` | Survives re-ordering if questions are ever shuffled in a future phase |
| — | No `auth` feature in scope | Out of scope per requirements; scaffold folders are not created to avoid dead code |
| — | Shimmer required for initial question load; `CircularProgressIndicator` for Submit button only | Enforces AGENTS.md UX contract: shimmer for content, spinner for actions |