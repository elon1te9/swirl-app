# Decisions

## Purpose

This file stores confirmed product and technical decisions for the swirl project.

If there is a conflict between this file and open questions, follow this file.

If there is a conflict between this file and older documentation, prefer the decision written here unless the project owner explicitly says otherwise.

## 1. Backend project structure

Decision:

Use a simplified ASP.NET Core API structure:

```text
Swirl.Api/
  Properties/
  Controllers/
  Data/
  Hubs/
  Interfaces/
  Migrations/
  Models/
  Services/
  appsettings.json
  Program.cs
  Swirl.Api.http
```

Folder responsibilities:

- `Controllers` — HTTP API controllers.
- `Data` — `AppDbContext`, EF Core configuration, database setup, seed logic.
- `Models` — database entities and request/response DTO models.
- `Interfaces` — service interfaces.
- `Services` — business logic services.
- `Migrations` — EF Core migrations.
- `Hubs` — optional folder for SignalR; do not use it in MVP unless explicitly requested.

Do not create folders:

- `DTOs`
- `Repositories`
- `Mapping`
- `Middleware`
- `Extensions`
- `Seed`

unless explicitly requested later.

## 2. Repository layer

Decision:

Do not use a separate repository layer in MVP.

Services may work with `AppDbContext` directly.

Reason:

This keeps the educational MVP simpler and closer to the preferred project structure.

## 3. DTO location

Decision:

Request and response DTO models should be placed in `Models`.

Reason:

The selected backend structure uses one `Models` folder for both database entities and API models.

## 4. Controllers and services

Decision:

Controllers must be thin.

Business logic must be placed in `Services`.

Service interfaces must be placed in `Interfaces`.

Controllers should:

- receive HTTP requests
- get current user id from JWT when needed
- call services
- return DTO responses

Controllers should not contain:

- password hashing
- JWT generation
- level unlocking
- streak calculation
- daily test generation
- progress calculation

## 5. Initial level availability

Decision:

The first level of each section is available immediately after registration.

All other levels are locked.

Final tests are locked until all normal levels in the section are completed.

Reason:

This gives the user freedom to choose any topic.

## 6. Level completion rule

Decision:

A level is completed only if the user finishes all exercises with 0 mistakes.

If the user has one or more mistakes:

- attempt is saved
- answers are saved
- level is not completed
- next level is not unlocked

## 7. Failed attempts and streak

Decision:

Failed level attempts still count as learning activity for streak.

Reason:

The user still practiced and completed a learning action.

## 8. Word learning rule

Decision:

A word becomes learned after the user views it in the Learn word flow and the app calls mark-learned endpoint.

Learned words remain learned even if the user later fails the level.

## 9. Daily test availability

Decision:

Daily test is available only if the user has at least 5 learned words.

If the user has fewer than 5 learned words, return unavailable state.

## 10. Daily test repeat behavior

Decision:

For MVP, allow one completed daily test per user per server date.

Reason:

This keeps streak and daily test state simple.

## 11. Streak date source

Decision:

Use server date for streak and daily test logic.

Do not rely on client device date.

## 12. Streak update frequency

Decision:

Streak can increase at most once per day.

Learning activities:

- successful level completion
- failed level attempt
- daily test completion

## 13. Answer checking

Decision:

Use exact normalized answer matching.

Normalization:

1. trim spaces
2. lowercase
3. replace repeated inner spaces with a single space

Not supported in MVP:

- typo tolerance
- multiple correct answers
- semantic answer matching

## 14. Correct answer visibility

Decision:

Do not show the correct answer immediately after a mistake in MVP.

The user should only see that the answer is incorrect.

## 15. Backend answer verification

Decision:

Backend must recalculate correctness.

Flutter's `isCorrect` is not trusted as the source of truth.

Final `mistakesCount`, level completion, and unlock logic are based on backend-calculated correctness using `exerciseId`, stored correct answer, and normalized `userAnswer`.

Reason:

This prevents accidental client-side inconsistencies and keeps progress reliable.

## 16. Minimal seed before auth

Decision:

Before implementing auth registration, the backend must have minimal seed data for avatars, sections, and levels.

This allows registration to assign avatar and create initial level progress.

Full words and exercises seed can be implemented later in Stage 5.

## 17. Level session loading

Decision:

Flutter must not request every exercise separately.

Correct flow:

1. Flutter requests full level session.
2. Backend returns all exercises.
3. Flutter completes exercises locally.
4. Flutter sends final answers once after the session is finished.

## 18. Unfinished level attempts

Decision:

Unfinished level attempts may be stored locally in Flutter.

Backend stores attempts only after the level is completed.

Reason:

This keeps MVP backend simpler.

## 19. Media storage

Decision:

Store media on backend under `wwwroot/media`.

Database stores relative media paths.

Example:

```text
/media/images/words/apple.png
/media/audio/words/apple.mp3
/media/avatars/avatar_1.png
```

Do not store absolute local file system paths in the database.

## 20. Avatars

Decision:

Use predefined avatars in MVP.

Users select avatar during registration.

Users may change avatar later if the endpoint is implemented.

User-uploaded avatars are out of MVP scope.

## 21. Seed data

Decision:

Use seed data for MVP content.

Seed should create:

- avatars
- sections
- levels
- words
- exercises
- exercise options

Admin panel UI is out of MVP scope.

## 22. Admin endpoints

Decision:

Do not implement admin content endpoints initially.

Use seed data first.

Admin endpoints may be added later if explicitly requested.

## 23. Auth

Decision:

Use JWT Bearer Authentication.

Public endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- static media from `/media`

All user-specific endpoints require JWT.

`GET /api/avatars` may be public or protected.

## 24. Refresh tokens

Decision:

Do not implement refresh tokens in MVP.

JWT access token is enough for the educational MVP.

## 25. Email confirmation and password reset

Decision:

Do not implement in MVP:

- email confirmation
- password reset by email
- email notifications

Reason:

Email functionality is out of MVP scope.

## 26. Frontend state management

Decision:

Use Riverpod for Flutter state management.

## 27. Frontend navigation

Decision:

Use go_router for Flutter navigation.

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

## 28. Frontend API client

Decision:

Use Dio for HTTP requests.

JWT must be sent in the header:

```text
Authorization: Bearer <token>
```

## 29. Frontend token storage

Decision:

Use `flutter_secure_storage` for JWT token storage.

## 30. Frontend media loading

Decision:

Flutter should load images and audio from backend URLs.

Do not hardcode learning media in Flutter.

## 31. UI style

Decision:

Use a light, soft, friendly, cartoon-like style.

Dark theme is out of MVP scope.

## 32. Platform scope

Decision:

MVP targets Android only.

Out of scope:

- iOS
- web
- desktop

## 33. Monetization scope

Decision:

Do not implement in MVP:

- monetization
- subscriptions
- ads
- internal currency

## 34. Gamification scope

Decision:

Do not implement in MVP:

- achievements
- leaderboard
- user levels
- internal currency

Streak is included in MVP.

## 35. Daily test algorithm

Decision:

Use simple random selection from learned words.

Do not implement spaced repetition in MVP.

## 36. Flutter offline behavior

Decision:

Do not implement full offline-first mode.

Allowed local storage:

- JWT token
- optional unfinished level attempt
- optional temporary cached state

## 37. Hubs folder

Decision:

Keep `Hubs` folder only if the project template contains it.

Do not use SignalR in MVP unless explicitly requested.

## 38. Error response format

Decision:

Use consistent JSON errors.

Recommended format:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": {
      "email": ["Email is required"]
    }
  }
}
```

## 39. Build verification

Decision:

After backend changes, run:

```bash
dotnet build
```

After Flutter changes, run:

```bash
flutter analyze
```

Run tests if they exist.

## Final rule

When implementing the project, prefer simple MVP-ready solutions over complex architecture.

Do not implement out-of-scope features unless explicitly requested by the project owner.
