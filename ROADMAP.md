# ROADMAP.md — quiz_app

> **Legend:** `[ ]` = Pending · `[x]` = Done · `[~]` = In Progress
> Update this file after every completed task or session. Never delete completed phases.

---

## Provider Rebuild Strategy (Project-Wide Rule)

> This rule applies to **every screen and widget** in the project. Read before building any UI.

Use `Consumer` and `Selector` to surgically scope widget rebuilds. **Never** use `context.watch` at the top of a `build()` method when only a subset of the provider's state is needed — that rebuilds the entire subtree on every `notifyListeners()` call.

| Tool | When to Use | Example |
|------|-------------|---------|
| `Selector<P, T>` | Widget needs **one specific field** from the provider. Rebuilds only when that field changes. | Progress bar watching `currentIndex` only |
| `Consumer<P>` | Widget needs **multiple fields** but should be scoped below the scaffold. Rebuilds when any relevant field changes. | Nav bar that needs `currentIndex`, `selectedAnswers`, and `state` |
| `context.read<P>()` | **Fire-and-forget actions only.** Never used inside `build()`. | `onPressed: () => context.read<QuizProvider>().selectAnswer(id, i)` |
| `context.watch<P>()` | **Allowed only at the screen root** when the entire screen must respond to a sealed state change. | Top-level `switch (state)` in `QuizScreen` |

---

## Navigation Strategy (Project-Wide Rule)

> Applies to every `GoRouter` call in the project.

| Method | Behavior | When to Use |
|--------|----------|-------------|
| `context.go(path)` | **Replaces** the entire navigation stack. Back button cannot return to the previous route. | Moving to a screen that must not be revisited once left |
| `context.push(path)` | **Pushes** onto the stack. Back button returns to the previous route. | Presenting supplemental content layered over an existing screen |

**Transition map for this app:**

| Transition | Method | Reason |
|------------|--------|--------|
| Home → Quiz (after load) | `.go('/quiz')` | User cannot back-navigate to Home mid-quiz; `PopScope` dialog handles exit explicitly |
| Quiz → Results (after submit) | `.go('/results', extra: result)` | Quiz is complete; back-to-quiz is an invalid state |
| Results → Home (retry) | `.go('/')` | Full stack reset; results screen must not remain on the back stack |
| Any future `/help` overlay | `.push('/help')` | Supplemental; back arrow returns the user to their previous screen naturally |

---

## Phase 0 — Project Bootstrap & Configuration
> Goal: Confirm the project compiles, dependencies are wired, and global infrastructure is in place.

### 0.1 Dependencies
- [x] Verify `pubspec.yaml` includes: `provider`, `go_router`, `shimmer`, `google_fonts`
- [x] Run `flutter pub get` and confirm zero errors

### 0.2 Theme
- [x] Define `AppTheme` in `core/theme/app_theme.dart` using **Material Design 3**
  - Light color scheme using `ColorScheme.fromSeed`
  - Apply `GoogleFonts` text theme globally
- [x] Wire `AppTheme.light` into `MaterialApp.router`

### 0.3 Global Routing Shell
- [x] Create `core/router/app_router.dart` with `GoRouter` instance
- [x] Define named route constants in `core/constants/route_names.dart`
  - `/` → Home Screen
  - `/quiz` → Quiz Question Screen
  - `/results` → Results Screen
- [x] Wire router into `MaterialApp.router` in `main.dart`

### 0.4 Global Widgets
- [x] Confirm `core/widgets/error_view.widget.dart` is implemented and reusable

### 0.5 Dependency Injection
- [x] Register `QuizService`, `QuizRepositoryImpl`, and `QuizProvider` via `MultiProvider` / `ChangeNotifierProxyProvider` in `main.dart`

---

## Phase 1 — Domain Layer
> Goal: Define the business contracts. Zero Flutter dependencies.

### 1.1 Models (`quiz/domain/models/`)
- [x] **`question.model.dart`** — `Question`
  ```
  id          : int
  text        : String
  options     : List<String>      // 4 labelled choices (A–D)
  correctIndex: int               // index into options
  ```
- [x] **`quiz_result.model.dart`** — `QuizResult`
  ```
  questions       : List<Question>
  selectedAnswers : Map<int, int>   // questionId → chosen index
  score           : int             // computed getter
  ```

### 1.2 Repository Interface (`quiz/domain/repositories/`)
- [x] **`quiz.repository.dart`** — `abstract class QuizRepository`
  - `Future<List<Question>> getQuestions()`
  - `Future<QuizResult> submitAnswers(List<Question>, Map<int,int> answers)`

---

## Phase 2 — Data Layer
> Goal: Implement the repository interface with in-memory mock data. No database.

### 2.1 Mock Service (`quiz/data/services/`)
- [x] **`quiz.service.dart`** — `QuizService`
  - Holds a `static const List<Map<String, dynamic>> _rawQuestions` with **10 hardcoded questions**
  - Each question has: `id`, `text`, `options` (4 choices), `correctIndex`
  - Sample topics: general knowledge / Flutter trivia (mix to keep it interesting)
  - `Future<List<Map<String,dynamic>>> fetchQuestions()` — simulates async with `Future.delayed(800ms)`

### 2.2 Error Mapper (`quiz/data/mappers/`)
- [x] **`quiz_error.mapper.dart`** — `QuizErrorMapper`
  - Converts raw `Exception` → human-readable `String` message
  - Handles: generic `Exception`, `FormatException`, unknown fallback

### 2.3 Repository Implementation (`quiz/data/repositories/`)
- [x] **`quiz.repository_impl.dart`** — `QuizRepositoryImpl implements QuizRepository`
  - Calls `QuizService.fetchQuestions()`, maps raw maps → `Question` domain models
  - Wraps calls in `try/catch`, maps errors via `QuizErrorMapper`
  - `submitAnswers` computes `QuizResult` in-memory and returns it

---

## Phase 3 — Presentation Layer: State & Provider
> Goal: Define sealed UI states and the ChangeNotifier that drives every screen.

### 3.1 Sealed States (`quiz/presentation/providers/`)
- [x] **`quiz_state.dart`** — Sealed class hierarchy
  ```dart
  sealed class QuizState {}
  class QuizInitial    extends QuizState {}
  class QuizLoading    extends QuizState {}
  class QuizLoaded     extends QuizState { final List<Question> questions; }
  class QuizError      extends QuizState { final String message; }
  class QuizSubmitting extends QuizState {}
  class QuizSubmitted  extends QuizState { final QuizResult result; }
  ```

### 3.2 Provider (`quiz/presentation/providers/`)
- [x] **`quiz.provider.dart`** — `QuizProvider extends ChangeNotifier`
  - State: `QuizState state`, `int currentIndex`, `Map<int,int> selectedAnswers`
  - `loadQuestions()` → transitions: `Initial → Loading → Loaded | Error`
  - `selectAnswer(int questionId, int chosenIndex)` → saves to `selectedAnswers`, calls `notifyListeners()`
  - `nextQuestion()` / `previousQuestion()` → increments/decrements `currentIndex`
  - `submitQuiz()` → transitions: `Loaded → Submitting → Submitted | Error`
  - `resetQuiz()` → clears all state back to `Initial`
  - Convenience getters:
    - `bool isLastQuestion`
    - `bool hasAnsweredCurrent`
    - `bool allAnswered` — used by `Selector` in Submit button's enabled state

---

## Phase 4 — Presentation Layer: Screens & Widgets
> Goal: Build all three screens with surgical rebuild scoping. Screens are passive.

### 4.1 Shared / Core Widgets
- [x] **`core/widgets/error_view.widget.dart`** — Accepts `message` + optional `onRetry` callback *(confirm exists)*

### 4.2 Quiz Shimmer Widget (`quiz/presentation/widgets/`)
- [x] **`quiz_shimmer.widget.dart`** — `QuizShimmerLoader`
  - Mimics the question card + 4 option tiles layout
  - Uses `shimmer` package; must visually match `QuizQuestionCard`
  - Pure stateless widget — no provider access needed

### 4.3 Progress Bar Widget (`quiz/presentation/widgets/`)
- [x] **`quiz_progress_bar.widget.dart`** — `QuizProgressBar`
  - Wraps `LinearProgressIndicator`
  - Uses `Selector<QuizProvider, double>` selecting `currentIndex / questions.length`
  - Fully isolated — the question card and option tiles do **not** rebuild when progress changes

### 4.4 Question Card Widget (`quiz/presentation/widgets/`)
- [x] **`quiz_question_card.widget.dart`** — `QuizQuestionCard`
  - Displays: question number badge and question text
  - Uses `Selector<QuizProvider, (int, String)>` selecting `(currentIndex, currentQuestion.text)`
  - Rebuilds **only** when the displayed question changes — not when the user picks an answer

### 4.5 Option Tile Widget (`quiz/presentation/widgets/`)
- [x] **`quiz_option_tile.widget.dart`** — `QuizOptionTile`
  - Displays one answer option with highlighted selected state
  - Each tile uses `Selector<QuizProvider, int?>` selecting `selectedAnswers[question.id]`
  - Tapping one option rebuilds **only that tile**, not all four
  - `onTap: () => context.read<QuizProvider>().selectAnswer(id, index)` — `read`, never `watch`

### 4.6 Bottom Navigation Bar Widget (`quiz/presentation/widgets/`)
- [ ] **`quiz_nav_bar.widget.dart`** — `QuizNavBar`
  - Contains Previous / counter label / Next or Submit button
  - Uses `Consumer<QuizProvider>` scoped to just this bar — question card and option tiles above it do not rebuild when nav state changes
  - All buttons use `context.read<QuizProvider>()` in their `onPressed` callbacks
  - Submit button disabled state: `Selector<QuizProvider, bool>` on `allAnswered`
  - Submit button loading state: `Selector<QuizProvider, bool>` on `state is QuizSubmitting`
  - Submit button shows `CircularProgressIndicator` while submitting; label otherwise

### 4.7 Home Screen (`core/screens/home_screen.dart`)
- [ ] Displays app name, brief description, and **"Start Quiz"** button
- [ ] Uses `Selector<QuizProvider, bool>` on `state is QuizLoading` to toggle the button's loading indicator — no full-page rebuild
- [ ] **"Start Quiz"** button:
  - `onPressed: () => context.read<QuizProvider>().loadQuestions()`
  - Shows `CircularProgressIndicator` while loading; disabled to prevent duplicate taps
- [ ] Navigation: Screen listens for `QuizLoaded` state via a `Consumer` listener pattern; on transition calls `context.go('/quiz')` — `.go` because Home must not remain on the back stack

### 4.8 Quiz Question Screen (`quiz/presentation/screens/quiz.screen.dart`)
- [ ] **Top-level sealed state switch** uses `context.watch<QuizProvider>()` — the only permitted `watch` call; the entire layout swaps per state
  ```dart
  final state = context.watch<QuizProvider>().state;
  return switch (state) {
    QuizInitial()               => const SizedBox.shrink(), // router guard redirects
    QuizLoading()               => const QuizShimmerLoader(),
    QuizError(:var message)     => ErrorView(message: message, onRetry: ...),
    QuizLoaded()                => const _QuizLoadedBody(),
    QuizSubmitting()            => const _SubmittingOverlay(),
    QuizSubmitted(:var result)  => _NavigateToResults(result: result),
  };
  ```
- [ ] `_QuizLoadedBody` — private widget composing sub-widgets, each with their own `Selector`:
  - `QuizProgressBar` — Selector on `currentIndex`
  - `QuizQuestionCard` — Selector on `(currentIndex, currentQuestion.text)`
  - Four `QuizOptionTile`s — each with a Selector on `selectedAnswers[question.id]`
  - `QuizNavBar` — Consumer on `currentIndex`, `selectedAnswers`, `state`
- [ ] `_NavigateToResults` — a `StatefulWidget` whose `initState` fires:
  ```dart
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.go('/results', extra: result);
  });
  ```
  Calling `.go()` directly inside `build()` is illegal; `addPostFrameCallback` defers it safely.
- [ ] `SnackBar` warning (via `ScaffoldMessenger`) if submit is attempted with unanswered questions — invoked from `QuizNavBar`'s callback, triggered by the Screen

### 4.9 Results Screen (`quiz/presentation/screens/results.screen.dart`)
- [ ] Receives `QuizResult` via `GoRouterState.extra` — screen owns its data directly; **no provider reads needed** since the result is fully contained in `extra`
- [ ] Displays:
  - **Score banner** — `7 / 10` in large, prominent typography
  - **Summary row** — Correct ✅ / Incorrect ❌ counts
  - **Scrollable review list** — one card per question:
    - Question text
    - User's chosen answer (green if correct, red if wrong)
    - Correct answer label (always green)
    - No multiple-choice options — answer strings only
- [ ] **"Retry Quiz"** button:
  1. `context.read<QuizProvider>().resetQuiz()`
  2. `context.go('/')` — `.go` to fully reset the stack; results must not remain reachable via back

---

## Phase 5 — Routing & Navigation
> Goal: Wire GoRouter so navigation is declarative, stack-safe, and uses `.go` / `.push` correctly.

- [ ] Route `/` → `HomeScreen`
- [ ] Route `/quiz` → `QuizScreen`
  - Redirect guard: if `QuizProvider.state is QuizInitial`, call `.go('/')` — prevents direct URL access
- [ ] Route `/results` → `ResultsScreen`
  - Redirect guard: if `GoRouterState.extra == null`, call `.go('/')` — prevents crash on direct URL access
- [ ] Verify final navigation call map against the project-wide Navigation Strategy table above

---

## Phase 6 — Polish & Production Readiness
> Goal: Ensure UX is solid and the codebase is clean.

### 6.1 UX Polish
- [ ] Animate option selection (`AnimatedContainer` — color + scale transition)
  - Only the tapped tile's `Selector` fires; animation is fully contained to that widget
- [ ] Add `PopScope` on `QuizScreen` wrapping a `showDialog` confirmation:
  - "Are you sure? Your progress will be lost."
  - **Continue Quiz** (dismisses dialog) / **Exit** → `context.go('/')` resets the stack

### 6.2 Accessibility & Resilience
- [ ] All interactive widgets have `Semantics` labels
- [ ] `QuizProvider.resetQuiz()` fully clears all state (no stale references)
- [ ] Audit: confirm zero `context.watch` or `Consumer` calls appear inside callbacks or `initState`
- [ ] Test all navigation guards: direct URL access to `/quiz` and `/results` redirects correctly

### 6.3 Code Quality
- [ ] Final `Selector` / `Consumer` / `read` audit across every widget — see Project-Wide Rule table
- [ ] All public classes and methods documented with `///` DartDocs
- [ ] No raw `print()` statements in production code
- [ ] All `const` constructors applied wherever possible
- [ ] Run `flutter analyze` with zero warnings

---

## Decisions & Notes

| Date | Decision | Rationale |
|------|----------|-----------|
| — | `context.watch` permitted **only** at the screen root for the sealed state `switch` | The entire widget tree swaps per state; granular scoping is impossible at this level. All sub-widgets use `Selector` or `Consumer` |
| — | Each `QuizOptionTile` has its own `Selector` keyed to its question's selected answer | Tapping one option rebuilds only that tile, not all four — O(1) rebuild instead of O(n) |
| — | `QuizProgressBar` and `QuizQuestionCard` use separate `Selector`s | Progress changes on navigation; question text changes on navigation; answer selection changes neither — they are independent concerns |
| — | `ResultsScreen` does not read from `QuizProvider` — consumes `GoRouterState.extra` directly | Result data is immutable at this point; reading from the provider creates an unnecessary dependency and risks stale state if `resetQuiz()` fires before the screen dismounts |
| — | All app transitions use `.go()`; `.push()` reserved for future supplemental/overlay routes only | Prevents the user from back-navigating into an invalid or completed state |
| — | Navigation from `QuizScreen → /results` deferred via `addPostFrameCallback` inside `_NavigateToResults` | Calling `context.go()` inside `build()` or a `switch` arm violates Flutter's render pipeline; the post-frame callback defers it safely |
| — | `QuizResult` computed in `QuizRepositoryImpl.submitAnswers`, not in the Provider | Keeps the Provider a thin orchestrator; business logic stays in the domain/data boundary |
| — | `selectedAnswers` uses `Map<int, int>` keyed by `question.id` | Survives re-ordering if questions are ever shuffled in a future phase |
| — | No `auth` feature in scope | Out of scope per requirements; scaffold folders are not created to avoid dead code |
| — | Shimmer for initial question load; `CircularProgressIndicator` for Submit button only | Enforces AGENTS.md UX contract: shimmer for content, spinner for button actions |