# Flutter tasks

## Goal

This file contains the recommended Flutter implementation plan for the swirl Android app.

Implement tasks stage by stage.

Do not jump to the next stage unless explicitly requested.

## Required docs

Before implementing Flutter tasks, read:

- `docs/00_PROJECT_OVERVIEW.md`
- `docs/03_API_CONTRACT.md`
- `docs/04_FRONTEND_ARCHITECTURE.md`
- `docs/05_LEARNING_LOGIC.md`
- `docs/06_DAILY_TEST_AND_STREAK.md`
- `docs/08_ERROR_HANDLING.md`
- `docs/12_UI_UX_GUIDE.md`

## Flutter stack

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
- Handle loading, error, and empty states on every screen that uses API data.

## Stage 1. Project setup

Tasks:

- Create Flutter project inside `frontend`.
- Configure Android target.
- Add dependencies.
- Configure app theme.
- Configure routing with go_router.
- Configure Dio API client.
- Configure secure token storage.
- Create base folder structure.
- Add base reusable UI components.

Recommended dependencies:

- `dio`
- `flutter_secure_storage`
- `go_router`
- `flutter_riverpod`
- `json_annotation`
- `json_serializable`
- `build_runner`
- `audioplayers` or `just_audio`

Expected result:

- App starts on Android.
- Basic routing works.
- API client can be configured with backend base URL.
- `flutter analyze` passes.

## Stage 2. Authentication screens

Screens:

- Loading screen
- First screen
- Login screen
- Sign up screen

Tasks:

- Create loading/splash screen.
- Create first/start screen.
- Create login form.
- Create sign up form.
- Load avatars for sign up.
- Implement login request.
- Implement registration request.
- Save JWT token after successful auth.
- Call `/api/auth/me` when needed to validate current user.
- Redirect authenticated user to Home page.
- Redirect unauthenticated user to First/Login screen.
- Show validation and API errors.

Validation:

Login:

- email is required
- email format should be valid
- password is required

Sign up:

- name is required
- email is required
- email format should be valid
- password is required
- confirm password is required
- password and confirm password must match
- avatar must be selected or default avatar must be used

Expected result:

- User can register.
- User can login.
- JWT is saved locally.
- User remains authenticated after app restart.
- Auth errors are shown clearly.

## Stage 3. Home and profile

Screens:

- Home page
- Profile

Tasks:

- Create Home page.
- Show user greeting.
- Show profile avatar icon.
- Show daily test card.
- Show continue learning block.
- Show short progress summary.
- Create Profile screen.
- Show name.
- Show avatar.
- Show current streak.
- Show best streak.
- Show learned words count.
- Show completed levels count.
- Show section progress.
- Implement avatar change if backend endpoint is ready.
- Implement logout.

Logout rules:

- remove JWT token from local storage
- clear local auth state
- redirect user to Login or First screen

Expected result:

- User can view home page.
- User can view profile.
- User can logout.
- Profile data is loaded from API.

## Stage 4. Sections and level map

Screens:

- Sections
- Level map
- Level pop-up

Tasks:

- Fetch sections from API.
- Show section title.
- Show section image.
- Show section description.
- Show section progress percent.
- Show completed levels count.
- Navigate to level map.
- Fetch levels of selected section.
- Show level statuses:
  - locked
  - available
  - completed
- Prevent starting locked levels.
- Show level pop-up for selected level.
- Show CEFR level.
- Show words count.
- Show exercises count.
- Show button to learn words.
- Show button to start training if words are already learned.

Expected result:

- User can open sections.
- User can open level map.
- Locked levels are visually disabled.
- Available levels can be opened.
- Completed levels can be repeated.

## Stage 5. Learn words

Screens:

- Level loading screen
- Learn word screen
- Learned words pop-up

Tasks:

- Fetch words for selected level.
- Show one word at a time.
- Show English word.
- Show Russian translation.
- Show transcription.
- Show part of speech if available.
- Show word image from backend URL.
- Play audio from backend URL.
- Navigate to next word.
- After last word, show learned words pop-up.
- Call mark-learned endpoint.
- Navigate to tasks.

Expected result:

- User can study all words of a level.
- Learned words are saved on backend.
- User can continue to exercises.
- Missing media does not crash the app.

## Stage 6. Exercises

Screens:

- Task with word input
- Word selection task
- Audio choice task

Tasks:

- Fetch full level session from API.
- Store session in local state.
- Show progress through exercises.
- Implement input tasks.
- Implement choice tasks.
- Implement audio choice tasks.
- Normalize answers for input tasks.
- Check answers locally.
- Save answers in local session state.
- Continue to next exercise after answer.
- Do not show correct answer after mistake in MVP.
- After last exercise, send all answers to backend.

Answer normalization:

- trim spaces
- lowercase
- replace repeated inner spaces with one space

Expected result:

- User can complete all exercises.
- App does not request backend for every exercise.
- Final result is sent once after all exercises.
- Correct and incorrect answer states are visible.

## Stage 7. Level result

Screens:

- Level win pop-up
- Lose level pop-up

Tasks:

- Show win pop-up if backend returns `isLevelCompleted = true`.
- Show lose pop-up if backend returns `isLevelCompleted = false`.
- Show mistakes count if needed.
- On success, update local progress state.
- On success, allow user to continue to next level or return to map.
- On failure, allow user to retry or return to map.
- Refresh level map after completion.

Expected result:

- Successful level completion opens next level.
- Failed level attempt does not open next level.
- User sees clear result state.

## Stage 8. Daily test

Screens:

- Daily test screen
- Daily test result screen or pop-up

Tasks:

- Show daily test card on Home page.
- Fetch daily test from API.
- If unavailable, show message:
  - "Изучите больше слов, чтобы открыть ежедневный тест"
- If available, reuse exercise UI.
- Complete daily test locally.
- Send result to backend.
- Show correct answers count.
- Update streak in local state.

Expected result:

- Daily test is available only after enough learned words.
- Daily test uses learned words.
- Daily test does not affect level progress.
- Daily test updates streak.

## Stage 9. Loading, errors, and empty states

Tasks:

- Add loading states for API requests.
- Add error states with retry button.
- Handle 401 by logging out user.
- Handle locked level error.
- Handle no internet connection gracefully.
- Handle empty sections or empty levels.
- Handle missing media gracefully.
- Show friendly messages instead of raw exceptions.

Expected result:

- App does not crash on API errors.
- User sees understandable messages.
- User can retry failed requests.

## Stage 10. UI polish

Tasks:

- Follow `docs/12_UI_UX_GUIDE.md`.
- Check small Android screens.
- Avoid overflow.
- Ensure forms work with keyboard open.
- Add smooth transitions.
- Add friendly loading indicators.
- Add friendly error messages.
- Check image loading.
- Check audio playback.
- Check route transitions.
- Check all MVP scenarios manually.

Expected result:

- App feels stable and pleasant.
- Main MVP flow works from registration to daily test.

## Important MVP constraints

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

## Verification after each stage

After each stage:

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
- no unrelated features were added
- API contract is followed
