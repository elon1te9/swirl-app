# Open questions

This file contains product and technical decisions that should be clarified before or during implementation.

Do not block backend MVP development if a question has a recommended default decision.

## 1. Initial level availability

Question:

Should the first level be available in all sections immediately, or only in the first section?

Recommended MVP decision:

The first level of each section is available immediately after registration.

Reason:

This gives the user freedom to choose any topic and matches the current MVP learning logic.

## 2. User name editing

Question:

Should the user be able to change their name after registration?

Recommended MVP decision:

No, not in the first MVP.

Reason:

It is not required for the core learning flow.

Possible future endpoint:

```text
PUT /api/profile/name
```

## 3. Learned words screen

Question:

Should the app have a separate screen with all learned words?

Recommended MVP decision:

No, not in the first MVP.

Reason:

Profile already shows learned words count. A full learned words dictionary can be added later.

## 4. Number of avatars

Question:

How many predefined avatars should be available in MVP?

Recommended MVP decision:

At least 4 avatars.

Reason:

This is enough for registration and profile customization in MVP.

## 5. Final test design

Question:

Should final test have a separate UI design?

Recommended MVP decision:

No.

Use the same exercise screens as normal level training.

Reason:

This reduces Flutter implementation time.

## 6. Unfinished level attempt storage

Question:

Should unfinished level attempts be saved on backend or only locally in Flutter?

Recommended MVP decision:

Store unfinished level attempt locally in Flutter.

Send data to backend only after the level is completed.

Reason:

This keeps backend simpler and matches the MVP performance principle.

## 7. Time spent tracking

Question:

Should backend store time spent on each answer or level?

Recommended MVP decision:

Store `time_spent_ms` for answers if Flutter sends it, but do not require it.

Reason:

The database supports it, but it is not critical for MVP.

## 8. Admin content management

Question:

Should the backend include admin endpoints for creating sections, levels, words, and exercises?

Recommended MVP decision:

No, not initially.

Use seed data for MVP content.

Reason:

There is no admin panel UI in MVP, and seed data is enough for early development.

Possible future endpoints:

```text
POST /api/admin/sections
POST /api/admin/levels
POST /api/admin/words
POST /api/admin/exercises
PUT /api/admin/words/{wordId}
PUT /api/admin/levels/{levelId}
DELETE /api/admin/words/{wordId}
```

## 9. Bulk import from JSON

Question:

Should Swagger endpoints support bulk import of words and exercises from JSON?

Recommended MVP decision:

No, not initially.

Reason:

Seed JSON files or C# seed logic are enough for the first version.

## 10. Correct answer visibility

Question:

Should the correct answer be shown immediately after a mistake?

Recommended MVP decision:

No.

Reason:

The current MVP logic says that after an error the user sees only wrong state, but the correct answer is not shown immediately.

## 11. Backend answer verification

Question:

Should backend verify answers again on level completion, or trust Flutter's `isCorrect` value?

Recommended MVP decision:

Backend should recalculate correctness on level completion.

Do not trust Flutter `isCorrect` for final progress.

Keep `isCorrect` in the API request only as optional client-side information if needed.

Reason:

This improves consistency and prevents accidental client-side mistakes.

## 12. Minimal seed before auth

Question:

Should auth registration be implemented before any content seed exists, or should minimal seed exist first?

Recommended MVP decision:

Minimal seed for avatars, sections, and levels should exist before auth.

Full words and exercises seed can remain in Stage 5.

Reason:

Registration needs avatars and existing levels to create initial user progress reliably.

## 13. Daily test repeat behavior

Question:

Can the user complete the daily test multiple times per day?

Recommended MVP decision:

One completed daily test per day.

Reason:

Simpler streak logic and simpler daily test state.

Possible alternative:

Allow repeat attempts but update only the latest result.

## 14. Daily test question count

Question:

How many questions should daily test contain?

Recommended MVP decision:

- minimum target: 15
- maximum target: 30
- if learned words count is less than 15, use fewer questions
- if learned words count is less than 5, daily test is unavailable

## 15. CEFR levels in early seed

Question:

Should all early seed levels use A1 or should they include A2/B1/etc.?

Recommended MVP decision:

Use mostly A1 for early seed content.

Reason:

The target audience is beginners, and CEFR complexity is not central to the MVP.

## 16. Media files availability

Question:

Should every word have real image and audio files in MVP?

Recommended MVP decision:

Prefer yes, but allow placeholder media paths during early backend development.

Reason:

API and database should support media from the start, but real assets can be added gradually.

## 17. Hubs folder

Question:

Should SignalR Hubs be used in MVP?

Recommended MVP decision:

No.

Reason:

swirl MVP does not require realtime features.

Keep the `Hubs` folder only if the project template includes it.

## 18. Repository layer

Question:

Should the backend use a repository layer?

Recommended MVP decision:

No, not initially.

Use services with `AppDbContext` directly.

Reason:

This keeps the educational MVP simpler.

## 19. DTO folder

Question:

Should DTOs be placed in a separate `DTOs` folder?

Recommended MVP decision:

No.

For this project structure, request and response DTO models should be placed in `Models`.

Reason:

The preferred project structure uses:

```text
Controllers/
Data/
Hubs/
Interfaces/
Migrations/
Models/
Services/
```

## 20. Refresh tokens

Question:

Should backend implement refresh tokens?

Recommended MVP decision:

No, not in MVP.

Reason:

JWT access token is enough for the educational MVP.

## 21. Password reset

Question:

Should backend implement password reset?

Recommended MVP decision:

No, not in MVP.

Reason:

Email functionality is out of MVP scope.

## 22. Dark theme

Question:

Should Flutter implement dark theme?

Recommended MVP decision:

No, not in MVP.

Reason:

The design target is a light, soft, friendly style.

## 23. Offline mode

Question:

Should Flutter support full offline-first mode?

Recommended MVP decision:

No.

Reason:

MVP only needs local token storage and optionally local unfinished attempt state.

## 24. Multiple correct answers

Question:

Should exercises support several correct translations?

Recommended MVP decision:

No.

Reason:

MVP answer checking uses one exact normalized correct answer.

## 25. Typo tolerance

Question:

Should input answers allow typos?

Recommended MVP decision:

No.

Reason:

MVP uses exact normalized matching.

## 26. Spaced repetition

Question:

Should daily test use a spaced repetition algorithm?

Recommended MVP decision:

No.

Reason:

MVP daily test uses simple random selection from learned words.

## Final note

Use recommended MVP decisions unless the project owner explicitly chooses a different behavior.
