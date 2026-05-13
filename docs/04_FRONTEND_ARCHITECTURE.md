# Frontend architecture

## Goal

This document describes the recommended Flutter architecture for the swirl Android app.

The frontend should be simple, understandable, and suitable for MVP development.

## Stack

Use:

- Flutter
- Dart
- Android
- Dio for HTTP requests
- flutter_secure_storage for JWT token storage
- go_router for navigation
- Riverpod for state management
- audioplayers or just_audio for word audio

## Recommended project structure

Use this structure:

```text
frontend/
  swirl_app/
    lib/
      main.dart
      app/
        app.dart
        router.dart
        theme.dart
      core/
        constants/
        errors/
        storage/
        network/
        utils/
      data/
        api/
        dto/
        repositories/
      domain/
        models/
        services/
      presentation/
        screens/
        widgets/
        state/
```

## Folder responsibilities

### app

Contains app-level setup:

- app root widget
- router configuration
- theme configuration
- global providers if needed

Recommended files:

```text
app/
  app.dart
  router.dart
  theme.dart
```

### core

Contains shared infrastructure and utilities.

Recommended folders:

```text
core/
  constants/
  errors/
  storage/
  network/
  utils/
```

Responsibilities:

- API base URL constants
- route names
- app constants
- token storage
- Dio client setup
- API error parsing
- answer normalization utilities
- shared helpers

### data

Contains API communication and data mapping.

Recommended folders:

```text
data/
  api/
  dto/
  repositories/
```

Responsibilities:

- API clients
- request DTOs
- response DTOs
- repository implementations
- conversion from DTOs to domain models

### domain

Contains app-level business models and simple domain services.

Recommended folders:

```text
domain/
  models/
  services/
```

Responsibilities:

- user model
- profile model
- section model
- level model
- word model
- exercise model
- daily test model
- answer checking helpers if needed

### presentation

Contains UI and state management.

Recommended folders:

```text
presentation/
  screens/
  widgets/
  state/
```

Responsibilities:

- screens
- reusable widgets
- Riverpod providers
- screen state classes
- controllers/notifiers

## State management

Use Riverpod.

Recommended approach:

- repositories are exposed through providers
- screen state is managed by StateNotifier, AsyncNotifier, or simple FutureProvider where appropriate
- avoid putting API calls directly inside widgets
- avoid large global mutable state

Example state areas:

- auth state
- profile state
- sections state
- levels state
- learn words state
- level session state
- daily test state

## Navigation

Use go_router.

Recommended routes:

```text
/splash
/first
/login
/signup
/home
/profile
/sections
/sections/:sectionId/levels
/levels/:levelId/learn
/levels/:levelId/tasks
/daily-test
```

Navigation rules:

- unauthenticated users should see only splash, first, login, and signup screens
- authenticated users should access home, profile, sections, levels, learning, tasks, and daily test
- locked levels should not be opened
- after logout, user should be redirected to login or first screen

## API communication

Use Dio.

Rules:

- configure one shared Dio instance
- set backend base URL in one place
- attach JWT token to protected requests
- parse JSON into DTOs
- convert DTOs into domain models if needed
- handle API errors consistently

Authorization header:

```text
Authorization: Bearer <token>
```

## Token storage

Use flutter_secure_storage for JWT token.

Flutter should:

- save token after successful login or registration
- read token on splash/loading screen
- remove token on logout
- attach token to API requests
- redirect to login if token is invalid or expired

## Media loading

Backend returns relative media paths, for example:

```text
/media/images/words/apple.png
/media/audio/words/apple.mp3
/media/avatars/avatar_1.png
```

Flutter should build full URLs using the backend base URL.

Rules:

- do not hardcode media assets in Flutter
- load word images from backend
- load word audio from backend
- handle missing images gracefully
- handle audio playback errors gracefully

## Exercise architecture

The app must not send a request for every exercise.

Correct flow:

1. Flutter calls `GET /api/levels/{levelId}/session`.
2. Backend returns all exercises.
3. Flutter stores the session in local state.
4. Flutter shows exercises one by one.
5. Flutter checks answers locally.
6. Flutter stores user answers locally.
7. After the last exercise, Flutter calls `POST /api/levels/{levelId}/complete`.
8. Backend returns win or lose result.
9. Flutter shows result pop-up.

## Answer checking

For MVP, Flutter may check answers locally because backend returns `correctAnswer`.

Input answer normalization:

1. trim spaces
2. convert to lowercase
3. replace repeated inner spaces with a single space

Rules:

- answer is correct only by exact normalized match
- typos are not accepted
- multiple correct answers are not supported in MVP
- correct answer is not shown immediately after mistake in MVP

## Local storage

For MVP, Flutter should locally store:

- JWT token
- current unfinished level attempt if needed
- simple cached state if needed

Recommended tools:

- `flutter_secure_storage` for JWT
- `shared_preferences` or Hive for unfinished attempt state if needed

Unfinished level attempt storage is optional for early MVP.

## Error handling

Flutter should handle:

- validation errors
- unauthorized errors
- locked level errors
- unavailable daily test
- network errors
- server errors
- missing media

Expected behavior:

- show clear user-friendly message
- show retry button where appropriate
- redirect to login on `401 Unauthorized`
- avoid app crash

## UI architecture

Keep screens focused.

Screens should:

- display state
- call controller/notifier actions
- not contain raw API logic
- not contain complex business logic

Reusable widgets should be extracted for:

- app buttons
- text fields
- loading states
- error states
- progress indicators
- section cards
- level nodes/cards
- word cards
- exercise option buttons
- result pop-ups

## MVP constraints

Do not implement unless explicitly requested:

- iOS
- web version
- dark theme
- push notifications
- offline-first mode
- user-uploaded avatars
- advanced analytics
- leaderboard
- achievements
- typo-tolerant answer checking
- spaced repetition algorithm

## Verification

After frontend changes:

```bash
flutter analyze
```

If tests exist:

```bash
flutter test
```

Also verify:

- app runs on Android emulator or device
- no major UI overflow
- API contract matches backend docs
- no unrelated features were added
