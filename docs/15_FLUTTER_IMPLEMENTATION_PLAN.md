# Flutter implementation plan

This document is the detailed implementation plan for the Swirl Flutter frontend.
It is based on the project documentation, `frontend/AGENTS.md`, and the current
ASP.NET Core backend in `backend/Swirl.Api`.

Use this file before implementing Flutter tasks. Do not treat it as permission to
add non-MVP features.

## 1. Backend status for Flutter

The backend currently builds successfully and exposes the following API surface.

Public endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/avatars`
- `/media/**`

JWT required endpoints:

- `GET /api/auth/me`
- `GET /api/profile`
- `PUT /api/profile/avatar`
- `GET /api/sections`
- `GET /api/sections/{sectionId}`
- `GET /api/sections/{sectionId}/levels`
- `GET /api/levels/{levelId}`
- `GET /api/levels/{levelId}/words`
- `POST /api/levels/{levelId}/words/mark-learned`
- `GET /api/levels/{levelId}/session`
- `POST /api/levels/{levelId}/complete`
- `GET /api/daily-test`
- `POST /api/daily-test/complete`

Backend facts Flutter must follow:

- JSON responses arrive in camelCase.
- `GET /api/avatars` is public in the current backend, but Stage 2 registration does not show an avatar picker.
- Media is served through `/media/**`.
- Flutter must build full media URLs from the backend origin.
- The backend recalculates answer correctness and does not trust Flutter `isCorrect`.
- `POST /api/levels/{levelId}/complete` requires answers for all active exercises in the level.
- `POST /api/levels/{levelId}/words/mark-learned` requires the level word ids.
- Daily test is available only from 5 learned words.
- Daily test currently uses only:
  - `english_to_russian_choice`
  - `russian_to_english_choice`
  - `russian_to_english_input`
  - `english_to_russian_input`
- Daily test may return fewer than 15 exercises, so Flutter must display the actual `exercisesCount`.
- Flutter must handle `daily_test_already_completed`.

## 2. Important docs

Before frontend tasks, Codex should read:

- `docs/03_API_CONTRACT.md`
- `docs/05_FRONTEND_ARCHITECTURE.md`
- `docs/06_LEARNING_LOGIC.md`
- `docs/07_DAILY_TEST_AND_STREAK.md`
- `docs/09_ERROR_HANDLING.md`
- `docs/12_FLUTTER_TASKS.md`
- `docs/13_UI_UX_GUIDE.md`
- `docs/DECISIONS.md`
- `frontend/AGENTS.md`

If `docs/DECISIONS.md` conflicts with another document, `docs/DECISIONS.md`
has priority.

## 3. Risks and notes

- Check the actual backend URL and port before Flutter integration.
- Check whether `UseHttpsRedirection` interferes with the Android emulator.
- Check real media URLs through Swagger/API before relying on images or audio.
- Stage 2 Flutter assigns a random predefined `avatarId` during registration. Avatar changing belongs to the profile/settings flow.
- Flutter must not hardcode word image or audio paths.
- Daily test `GET` unavailable is a normal response, not an exception.
- Daily test complete can return `not_enough_learned_words` or `daily_test_already_completed`.

## 4. Recommended Flutter structure

The main project recommendation is the structure from `frontend/AGENTS.md`:

```text
lib/
  main.dart
  app/
  core/
  data/
  domain/
  presentation/
```

For the student MVP, keep the code simple:

- Do not create unnecessary abstractions.
- Do not build excessive Clean Architecture.
- Do not add a complex repository layer unless it clearly reduces duplication.
- Keep UI, API, state, and models separated.
- Do not put API requests directly inside widgets.

Recommended simple folders:

```text
lib/
  main.dart
  app/
    app.dart
    router.dart
    theme.dart
  core/
    network/
    storage/
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

## 5. Implementation stages

### Stage 1. Flutter project setup

- Create Flutter project in `frontend/swirl_app`.
- Add dependencies:
  - `dio`
  - `flutter_secure_storage`
  - `go_router`
  - `flutter_riverpod`
  - `audioplayers` or `just_audio`
- Set up `ProviderScope`.
- Set up `MaterialApp.router`.
- Set up theme.
- Set up Dio.
- Set up token storage.
- Set up base widgets.
- Run `flutter analyze`.

### Stage 2. Auth

- Create `SplashScreen`.
- Create `FirstScreen`.
- Create `LoginScreen`.
- Create `SignUpScreen`.
- Register with `POST /api/auth/register`.
- Send a random predefined `avatarId` during registration.
- Log in with `POST /api/auth/login`.
- Validate current user with `GET /api/auth/me`.
- Save JWT.
- Add Dio `Authorization` header.
- Implement logout.
- Handle `401`.

### Stage 3. Home and Profile

- Load profile with `GET /api/profile`.
- Create `HomeScreen`.
- Create `ProfileScreen`.
- Change avatar with `PUT /api/profile/avatar`.
- Implement logout.
- Refresh profile after profile changes.

### Stage 4. Sections and Level Map

- Load sections with `GET /api/sections`.
- Load level map with `GET /api/sections/{sectionId}/levels`.
- Load level details with `GET /api/levels/{levelId}`.
- Support statuses: `locked`, `available`, `completed`.
- Create level popup.
- Disable locked levels in UI.

### Stage 5. Learn Words

- Load words with `GET /api/levels/{levelId}/words`.
- Show word card.
- Load image/audio from backend media URL.
- Mark learned with `POST /api/levels/{levelId}/words/mark-learned`.
- Remember that a final test may have no words.
- Add missing media fallback.

### Stage 6. Exercises

- Load full session once with `GET /api/levels/{levelId}/session`.
- Do not send a request per exercise.
- Keep local session state.
- Implement input tasks.
- Implement choice tasks.
- Implement audio choice tasks.
- Check answers locally for immediate UI feedback.
- Normalize input answers:
  - trim
  - lowercase
  - repeated spaces to one
- Do not show the correct answer immediately after a mistake.
- Complete once after the final exercise with `POST /api/levels/{levelId}/complete`.
- Trust backend result for progress, mistakes, unlocks, and streak.

### Stage 7. Result

- Show win popup.
- Show lose popup.
- Show `mistakesCount`.
- Use `openedNextLevelId` when present to refresh and show the unlocked level on the map.
- Refresh levels and profile.
- Add retry.
- Add navigation back to the current section level map.

### Stage 8. Daily Test

- Load daily test with `GET /api/daily-test`.
- Show unavailable state.
- Reuse exercise widgets.
- Complete with `POST /api/daily-test/complete`.
- Answer payload uses `wordId` and `exerciseType`.
- Daily exercise `id` is only a local UI id.
- Handle `daily_test_already_completed`.
- Refresh profile after completion.

### Stage 9. Loading/Error/Empty states

- Add loading state on every API screen.
- Add error state with retry.
- Add empty state.
- Handle `validation_error`.
- Handle `invalid_credentials`.
- Handle `unauthorized`.
- Handle `level_locked`.
- Handle `not_enough_learned_words`.
- Handle `daily_test_already_completed`.
- Handle media 404 and audio failure.

### Stage 10. UI polish

- Follow `docs/13_UI_UX_GUIDE.md`.
- Use light theme only.
- Use a soft friendly style.
- Use rounded cards.
- Use big buttons.
- Use readable text.
- Use simple animations only.
- Avoid overflow.
- Ensure forms work with the keyboard.

## 6. Screens

- `SplashScreen`
- `FirstScreen`
- `LoginScreen`
- `SignUpScreen`
- `HomeScreen`
- `ProfileScreen`
- `SectionsScreen`
- `LevelMapScreen`
- `LearnWordScreen`
- `TasksScreen`
- `DailyTestScreen`
- level details popup
- win popup
- lose popup
- daily result popup

## 7. Dart models

- `UserModel`
- `AuthResponseModel`
- `AvatarModel`
- `ProfileModel`
- `SectionProgressModel`
- `SectionModel`
- `LevelModel`
- `LevelDetailsModel`
- `WordModel`
- `ExerciseModel`
- `LevelSessionModel`
- `LevelAnswerModel`
- `CompleteLevelResultModel`
- `DailyTestModel`
- `DailyTestAnswerModel`
- `CompleteDailyTestResultModel`

Keep models simple. Add a model only when a backend response needs to be parsed.

## 8. Controllers and API classes

Use the simple MVP flow:

```text
Screen -> Controller -> Api/Storage
Api -> Dio request
Model -> parses JSON
```

API classes:

- `AuthApi`
- `ProfileApi`
- `SectionApi`
- `LevelApi`
- `DailyTestApi`

Controllers:

- `AuthController`
- add other controllers only when a screen needs to combine API calls with storage or repeated logic

Do not create frontend services or repositories unless the current simple flow
becomes hard to read.

## 9. State / Riverpod

Providers:

- `dioProvider`
- `tokenStorageProvider`
- `authApiProvider`
- `authControllerProvider`
- `profileProvider`
- `sectionsProvider`
- `levelsProvider(sectionId)`
- `levelDetailsProvider(levelId)`
- `learnWordsProvider(levelId)`
- `levelSessionProvider(levelId)`
- `dailyTestProvider`

Use Riverpod mostly to create dependencies.

Use `FutureProvider` only for simple read-only API screens where it keeps the
code shorter.

Keep form input, loading flags, selected ids, and error text inside
`StatefulWidget` screens.

Do not use `Notifier`, `AsyncNotifier`, or `StateNotifier` in early MVP stages
unless there is a real repeated state problem.

## 10. Reusable widgets

- `AppButton`
- `AppTextField`
- `PasswordField`
- `LoadingView`
- `ErrorView`
- `EmptyView`
- `AvatarCircle`
- `SectionCard`
- `LevelCard`
- `WordCard`
- `AudioButton`
- `ExerciseOptionButton`
- `ExerciseInputCard`
- `ExerciseProgressBar`
- `ResultPopup`
- `StatCard`
- `ProgressBar`

## 11. Routes

- `/splash`
- `/first`
- `/login`
- `/signup`
- `/home`
- `/profile`
- `/sections`
- `/sections/:sectionId/levels`
- `/levels/:levelId/learn`
- `/levels/:levelId/tasks`
- `/daily-test`

## 12. API, JWT and media rules

- Keep `backendOrigin` separate from `apiBaseUrl`.
- `apiBaseUrl = backendOrigin + /api`.
- Build media URLs from `backendOrigin`, not from `apiBaseUrl`.
- JWT storage key: `swirl_access_token`.
- Dio interceptor adds `Authorization`.
- `401` clears token and redirects to auth flow.
- Do not store passwords.
- Do not calculate streak locally.

Media URL rule:

- `null` or empty -> no media
- starts with `http` -> use as is
- starts with `/` -> `backendOrigin + path`
- otherwise -> `backendOrigin + / + path`

## 13. Error handling

Map backend/API errors to friendly UI behavior:

- `validation_error`: show field errors when possible, otherwise show form-level message.
- `invalid_credentials`: show invalid email/password message.
- `email_already_exists`: show duplicate email message.
- `unauthorized`: clear token and redirect to login/first screen.
- `not_found`: show missing resource message with back/retry where appropriate.
- `level_locked`: show locked level message and refresh level map.
- `not_enough_learned_words`: show daily test unavailable state.
- `daily_test_already_completed`: show already completed today state.
- `internal_error`: show friendly retryable server error.
- network errors: show connection message and retry button.

Do not show raw exceptions to users.

## 14. Verification

After every Flutter stage:

- Run `flutter analyze`.
- Run `flutter test` if tests exist.
- Run Android emulator smoke test.

Before Flutter integration, verify through Swagger/Postman:

- static media
- register
- login
- me
- profile
- sections
- levels
- words
- mark-learned
- session
- complete level
- daily unavailable
- daily available
- daily complete
- daily complete twice
- locked level
- validation errors

## 15. What not to do in MVP

- no iOS
- no web
- no desktop
- no dark theme
- no push notifications
- no achievements
- no leaderboard
- no internal currency
- no offline-first
- no refresh tokens
- no password reset
- no user-uploaded avatars
- no complex spaced repetition
- no typo tolerance
- no multiple correct answers
- no excessive Clean Architecture
