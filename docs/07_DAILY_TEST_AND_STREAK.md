# Daily test and streak

## Daily test purpose

The daily test helps the user repeat already learned words.

It is shown on the Home page as a separate card.

Daily test result does not block progress by sections or levels.

## Daily test availability

The daily test is available only if the current user has at least 5 learned words.

If the user has fewer than 5 learned words, return unavailable response.

Example unavailable response:

```json
{
  "date": "2026-05-13",
  "isAvailable": false,
  "reason": "Not enough learned words"
}
```

## Daily test date

Use server date for daily test generation.

For MVP, the daily test updates every day at 00:00 by server time.

Store the daily test date in `daily_tests.test_date`.

## Daily test generation

Algorithm:

1. Get all learned words of the current authenticated user.
2. If learned words count is less than 5, return unavailable response.
3. Shuffle learned words.
4. Select from 15 to 30 words if possible.
5. If the user has fewer than 15 learned words, use fewer questions.
6. For each selected word, randomly choose an exercise type.
7. For choice exercises, generate 4 options:
   - 1 correct option
   - 3 incorrect options
8. Return exercises to Flutter.

## Daily test exercise types

Daily test may use the same exercise types as normal levels:

- `picture_to_english_input`
- `english_to_russian_choice`
- `russian_to_english_choice`
- `russian_to_english_input`
- `english_to_russian_input`
- `audio_to_russian_choice`

For MVP, it is acceptable to use only a subset of these types if this makes implementation faster.

## Daily test response

Available response example:

```json
{
  "date": "2026-05-13",
  "isAvailable": true,
  "exercisesCount": 20,
  "exercises": [
    {
      "id": 501,
      "wordId": 1,
      "type": "russian_to_english_input",
      "questionText": "яблоко",
      "questionImageUrl": null,
      "questionAudioUrl": null,
      "correctAnswer": "apple",
      "options": []
    }
  ]
}
```

Rules:

- `id` may be generated dynamically for daily test exercises.
- `wordId` must reference a learned word of the current user.
- For MVP, `correctAnswer` may be returned to Flutter.
- Choice options should be shuffled.

## Daily test completion

Flutter completes daily test by calling:

```text
POST /api/daily-test/complete
```

Request example:

```json
{
  "answers": [
    {
      "wordId": 1,
      "exerciseType": "russian_to_english_input",
      "userAnswer": "apple",
      "isCorrect": true
    }
  ]
}
```

Response example:

```json
{
  "completed": true,
  "correctAnswers": 18,
  "totalAnswers": 20,
  "currentStreak": 5,
  "bestStreak": 7
}
```

Backend should:

- get current user id from JWT
- save or update `daily_tests` row for current server date
- save `daily_test_answers`
- count correct answers
- set `is_completed = true`
- update streak
- return score and streak data

## Daily test database rules

Table `daily_tests` should have unique constraint:

```text
unique(user_id, test_date)
```

This prevents duplicate daily test rows for the same user and date.

If a user repeats the daily test on the same date, implementation should either:

- update the existing daily test result, or
- return the existing completed result

For MVP, prefer updating the existing daily test result only if explicitly needed. Otherwise, allow one completed daily test per day.

## Streak purpose

Streak shows how many consecutive days the user has performed learning activity.

Streak data is stored in `user_profiles`:

- `current_streak`
- `best_streak`
- `last_activity_date`

## Learning activities

The following actions count as learning activity:

- successful level completion
- failed level attempt
- daily test completion

For MVP, streak updates once per day when the user finishes any level attempt or daily test.

## Streak update rules

Use server date.

If `last_activity_date` is null:

```text
current_streak = 1
last_activity_date = today
```

If `last_activity_date` is yesterday:

```text
current_streak = current_streak + 1
last_activity_date = today
```

If `last_activity_date` is today:

```text
current_streak does not change
```

If `last_activity_date` is earlier than yesterday:

```text
current_streak = 1
last_activity_date = today
```

After updating `current_streak`, update best streak:

```text
best_streak = max(best_streak, current_streak)
```

## Important streak constraints

- Streak must not increase more than once per day.
- Failed level attempt still counts as learning activity.
- Daily test completion counts as learning activity.
- Viewing words without completing a level or daily test does not have to update streak in MVP.
- Streak is tied to server date, not client device date.

## Out of scope for MVP

Do not implement unless explicitly requested:

- push reminders
- email reminders
- streak freeze
- streak recovery
- streak calendar
- timezone settings per user
- complex spaced repetition scheduling
