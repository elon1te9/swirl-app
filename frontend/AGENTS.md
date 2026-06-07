# Frontend AGENTS.md

This folder contains the Flutter Android app for swirl.

## Important docs

Before making Flutter changes, read:

- `../AGENTS.md`
- `../docs/00_PROJECT_OVERVIEW.md`
- `../docs/03_API_CONTRACT.md`
- `../docs/06_LEARNING_LOGIC.md`
- `../docs/07_DAILY_TEST_AND_STREAK.md`
- `../docs/09_ERROR_HANDLING.md`
- `../docs/12_FLUTTER_TASKS.md`
- `../docs/15_FLUTTER_IMPLEMENTATION_PLAN.md`
- `../docs/17_FLUTTER_SIMPLE_ARCHITECTURE.md`

## Flutter stack

Use:

- Flutter
- Dart
- Android
- Dio for HTTP requests
- flutter_secure_storage for JWT token storage
- go_router for navigation
- Riverpod for dependency providers and simple shared state
- audioplayers or just_audio for audio playback

## Recommended project structure

Use this Flutter structure:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    storage/
    network/
    utils/
  data/
    api/
  domain/
    models/
  presentation/
    screens/
    widgets/
    state/
```

## Folder responsibilities

- `app` — app root, router, theme.
- `core` — shared API client, token storage, media URL helpers, utilities.
- `data` — API classes that send HTTP requests.
- `domain` — simple models parsed from backend JSON.
- `presentation` — screens, widgets, simple controllers and providers.

## Simple frontend architecture

For MVP stages, use this flow:

```text
Screen -> Controller -> Api/Storage
Api -> Dio request
Model -> parses JSON
```

Riverpod should mostly create dependencies such as `dioProvider`,
`authApiProvider`, and `authControllerProvider`.

Keep local form state, loading flags, selected ids, and error text inside
`StatefulWidget` screens when it keeps the code easier to read.

Do not add repositories, service interfaces, `Notifier`, `AsyncNotifier`, or
`StateNotifier` unless a real repeated problem appears.

## General rules

- Keep UI separate from API calls.
- Do not hardcode learning content in Flutter.
- Load sections, levels, words, exercises, profile, and daily test from backend API.
- Store JWT token in secure local storage.
- Send JWT token in the `Authorization` header.
- Use backend media URLs for images and audio.
- Do not send a request for every exercise.
- Load a full level session once.
- Complete exercises locally.
- Send final result to backend after all exercises are completed.

## Auth rules

Flutter should:

- save JWT after successful registration or login
- during registration, send a random predefined `avatarId` from the simple MVP avatar set
- attach JWT to protected API requests
- check stored JWT on loading screen
- call `/api/auth/me` to validate current user when needed
- redirect unauthenticated user to First/Login screen
- remove JWT on logout
- redirect to Login or First screen after logout

## Navigation routes

Use routes similar to:

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

## Exercise flow

Correct flow:

1. User selects available level.
2. If words are not learned, user goes to Learn word screen.
3. After learning words, Flutter calls mark-learned endpoint.
4. Flutter requests full level session.
5. Flutter shows exercises one by one.
6. Flutter checks answers locally.
7. Flutter stores answers in local session state.
8. After the last exercise, Flutter sends all answers to backend.
9. Backend returns success or failure.
10. Flutter shows win or lose result.

## Answer normalization

For input exercises, normalize both user answer and correct answer:

1. trim spaces
2. convert to lowercase
3. replace repeated inner spaces with one space

Rules:

- exact normalized match is required
- typos are not accepted
- multiple correct answers are not supported in MVP

## Error handling

Flutter should handle API errors consistently.

Expected behavior:

- show validation errors under form fields when possible
- redirect to login on `401 Unauthorized`
- show locked level state on `level_locked`
- show unavailable daily test state when there are not enough learned words
- show retry button for network or server errors
- avoid app crashes on missing media or API failures

## UI rules

The app should have a soft, friendly, cartoon-like style.

MVP UI requirements:

- avoid overflow on small Android screens
- make forms usable when keyboard is open
- make lists scrollable
- show loading states
- show empty states
- show error states
- keep transitions smooth enough for MVP

## MVP constraints

Do not implement unless explicitly requested:

- iOS
- web version
- monetization
- subscriptions
- ads
- push notifications
- email notifications
- leaderboard
- achievements
- internal currency
- user levels
- automatic English level detection
- user-uploaded avatars
- dark theme
- advanced analytics
- full offline-first mode
- typo-tolerant answer checking
- spaced repetition algorithm

## Commands

Analyze:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run app:

```bash
flutter run
```

## Verification

After each Flutter task:

- run `flutter analyze`
- run tests if tests exist
- ensure app runs on Android emulator or device
- check for major UI overflow
- ensure API contract matches docs
- report what was changed
- report analyze or test result

## Task workflow

When asked to implement a Flutter stage:

1. Read the relevant docs.
2. Implement only the requested stage.
3. Do not implement unrelated features.
4. Keep code simple and MVP-ready.
5. Use the documented project structure.
6. Run verification commands.
7. Summarize changes.
