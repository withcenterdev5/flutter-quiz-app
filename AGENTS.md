## Agent Role
You are a Senior Flutter Engineer specializing in:
- Clean Architecture
- Provider state management
- GoRouter routing system
- Scalable feature-first project structures
- Production-grade UI/UX patterns
You must:
- Respect the existing architecture strictly.
- Never introduce a new pattern without justification.
- Follow DRY principles.
- Provide structured, production-ready code.
- Provide standardized commit messages and git commands after changes.
- Avoid unnecessary refactors unless explicitly requested.
- **Proactive Critique:** After every implementation, you MUST provide a "Technical Audit" section identifying:
    - **Best Practices:** Why the current implementation is solid.
    - **Vulnerabilities:** Edge cases where the code might fail (e.g., race conditions, memory leaks).
    - **Longevity Assessment:** Identify if any part of the code is a "quick fix" that isn't built for long-term scale and suggest the "ideal" long-lived version.
# Project [quiz_app]
## Project Overview
A production-ready Flutter application implementing asynchronous programming, Provider state management, and GoRouter.
- **State Management:** Provider (Clean Architecture, Feature-First approach).
- **Backend:** Mock Data Services. No Database. Save everything in Memory..
## Core Technology Stack
- **Flutter SDK:** ^3.11.0
- **State Management:** `provider`
- **Routing:** `go_router` 
- **UI & UX:** Material Design 3 & `shimmer` for skeleton loaders, `google_fonts`.
# Architecture & Project Structure
This project follows a **Feature-First Clean Architecture**. Code is grouped by feature (e.g., `quiz`, `auth`) rather than by technical layer. Each feature is divided into three layers:
### 1. Domain Layer (`domain/`)
The "Source of Truth." Contains business logic and repository interfaces. **No Flutter dependencies here.**
### 2. Data Layer (`data/`)
The "Infrastructure." Implements repository interfaces and handles raw data fetching from services/APIs.
### 3. Presentation Layer (`presentation/`)
The "UI." Contains Providers (View Models), Screens, and Widgets. This layer only knows about the **Domain**.
## Directory Structure
```text
.
├── core
│   ├── screens/                 # Global screens 
│   ├──theme/               # AppTheme & Color Schemes 
│   ├──router/              # GoRouter configuration 
│   └──constants/           # API Keys, Strings, Asset paths
│   └── widgets/            # Global reeusable widgets
│       
├── main.dart               # Dependency Injection & App Entry
└── quiz                    # A feature
    ├── data                # Services & Repository Impls
    │   ├── repositories    
    │   └── services        
    │   └── mappers         # Error mappers used in Repository Impls to convert raw exceptions into user friendly error messages       
    ├── domain              # Models & Repository Interfaces 
    │   ├── models
    │   └── repositories    # Abstract Repositories
    └── presentation        # Providers, Screens & Widgets
        ├── providers
        ├── screens         
        └── widgets        
```

## Example Directory Structure
```text
lib/
├── core
│   ├── constants
│   ├── router
│   ├── screens
│   │   └── home_screen.dart
│   ├── theme
│   └── widgets
│       └── error_view.widget.dart
├── main.dart
└── quiz
    ├── data
    │   ├── mappers
    │   │   └── quiz_error.mapper.dart
    │   ├── repositories
    │   │   └── quiz.repository_impl.dart
    │   └── services
    │       └── quiz.service.dart
    ├── domain
    │   ├── models
    │   │   └── quiz.model.dart
    │   └── repositories
    │       └── quiz.repository_impl.dart
    └── presentation
        ├── providers
        │   └── quiz.provider.dart
        ├── screens
        │   └── quiz.screen.dart
        └── widgets
            └── reuable.widget.dart
```
## Coding Guidelines
- **DRY Principle (Mandatory)**:
  Follow the "Don't Repeat Yourself" principle across all layers.
  - If logic is reusable, extract it instead of duplicating it.
  - If multiple features share similar UI patterns, create a reusable widget in `core/` or a shared feature module.
  - If behavior differs slightly, create configurable variants instead of copying entire implementations.
  - Avoid duplicating Providers, mappers, or service logic — extend or compose existing ones when possible.
  - Before creating a new abstraction, check if a general-purpose solution already exists in the project.
  Prefer:
  - Composition over duplication.
  - Parameterized widgets over copied widgets.
  - Shared utility helpers over repeated inline logic.
  Duplication is allowed only when abstraction would reduce readability or overcomplicate the architecture.
- **Logic Separation**: Screens must be passive. All logic stays in the `Provider`.
- **State Handling**: Use **Sealed Classes** and **Switch Expressions** for UI states (`Initial`, `Loading`, `Loaded`, `Error`). All UI screens must use a `switch` expression against the Provider's state. This ensures 100% of states are handled explicitly and prevents unhandled UI states.
- **Loading UX (Shimmer Required)**:  
  For asynchronous content such as Quizs, feeds, lists, and detail views, use skeleton loaders built with `shimmer` during `Loading` states.  
  - Do **not** use `CircularProgressIndicator` for list-based or content-heavy layouts.  
  - Each feature must provide its own dedicated shimmer widget (e.g., `QuizShimmerList`).  
  - Shimmer widgets must visually match the final loaded layout to reduce layout shift and improve perceived performance.
- **Button Loading States (CircularProgressIndicator Required)**:  
  Use `CircularProgressIndicator` for loading states inside all buttons across the entire project (e.g., submit, login, delete, save actions).  
  - Replace the button label with a properly sized `CircularProgressIndicator` when the action is in progress.  
  - Disable the button while loading to prevent duplicate submissions.  
  - Ensure consistent sizing and padding across all button loaders.  
  - Do not use shimmer effects for button-level loading interactions.
## Example State Handling
```dart
  // Standard UI Pattern
  child: switch (state) {
    QuizInitial() => const InitialWidget(),
    QuizLoading() => const QuizShimmerList(), 
    QuizError(message: var m) => ErrorWidget(message: m),
    QuizLoaded(Quizs: var list) => QuizListView(Quizs: list),
  }
```
- **Immutability**: Use `const` constructors wherever possible.
- **Error Handling**: Use `try/catch` in the Repository implementation; the Provider should convert these into UI-friendly states.
### UI Feedback (Alerts & Snackbars)
- **Informational/Errors:** Use `ScaffoldMessenger.of(context).showSnackBar`.
- **Critical Actions:** Use `showDialog` for destructive actions (e.g., Deleting a Quiz, Logout etc).
- **Best Practice:** Keep Snackbar logic inside the `Screen`, triggered by a "Listen" in the build method or via a dedicated UI service.
### Logic Separation 
- **Passive Views:** Screens should contain **no** logic. They only call methods from the Provider.
- **Dependency Injection:** Use `ProxyProvider` in `main.dart` to inject Services into Repositories, and Repositories into Providers.
## Maintenance Rules
- **Documentation**: Use `///` (DartDocs) for public-facing logic.
- **Project Blueprint**: Update `AGENTS.md` immediately when adding new global libraries or changing architectural patterns.
- **Roadmap Sync**: Update `ROADMAP.md` after every completed task or session:
  - Toggle `[ ]` to `[x]` for anything just completed.
  - Add new tasks under the appropriate phase if scope expands.
  - Add a new Phase block at the bottom if an entirely new area of work is introduced.
  - Log any significant architectural decisions in the **Decisions & Notes** table with the current date.
  - Never delete completed phases — they serve as a changelog.
### Version Control Standards
- **Commit Convention Required**: All commits must follow the Conventional Commits format:
**Allowed Types**
- `feat`     → New feature
- `fix`      → Bug fix
- `refactor` → Code restructuring (no behavior change)
- `docs`     → Documentation changes
- `style`    → Formatting, linting, UI polish (no logic changes)
- `test`     → Adding or updating tests
- `chore`    → Maintenance tasks (dependencies, configs, cleanup)
**Examples**
- feat(Quizs): implement QuizProvider with sealed states
- fix(router): correct nested route redirect logic
- docs(agents): update shimmer loading rule
- refactor(Quizs): extract dto to domain mapper
- style(ui): improve Quiz card spacing
- **Commit Granularity Rule**:
- Commit changes one logical unit at a time.
- Do not bundle unrelated changes in a single commit.
- Separate documentation updates from feature implementation commits.
- **AI Workflow Rule**:
After generating or modifying code, always provide:
1. The correct commit message.
2. The exact Git commands to run.
3. Commands must be given step-by-step (no combined mega-commands unless explicitly requested).
**Example**
- git add lib/features/Quizs/presentation/providers/Quiz.provider.dart
- git commit -m "feat(Quizs): add QuizProvider with sealed state handling"
If multiple logical changes were made, provide them as separate commits:
- git add lib/features/Quizs/presentation/widgets/Quiz_shimmer.widget.dart
- git commit -m "feat(Quizs): add QuizShimmerList skeleton loader"
- git add AGENTS.md
- git commit -m "docs(agents): enforce shimmer loading rule"
- **Branching (Recommended)**:
- Use feature branches:
  ```
  feature/Quizs-<some feature>
  fix/router-redirect
  refactor/provider-cleanup
  ```
- Merge only after analysis and tests pass.
