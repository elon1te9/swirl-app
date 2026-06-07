# Learning logic

## Core principle

The app must not send a separate request for every exercise.

Correct level flow:

1. Flutter requests the full level session from the backend.
2. Backend returns level data and all exercises.
3. Flutter runs the exercise session locally.
4. Flutter checks answers locally during the session.
5. Flutter sends all answers to the backend after the level is finished.
6. Backend saves the attempt, answers, progress, unlocks the next level if needed, and updates streak.

## Sections

The MVP contains 4 sections:

- Food
- Science
- Health
- Wardrobe

Each section contains:

- 5 normal levels
- 1 final test

## Level statuses

Allowed level statuses:

- `locked`
- `available`
- `completed`

Meaning:

- `locked` — user cannot start this level.
- `available` — user can start this level.
- `completed` — user completed this level with 0 mistakes and can repeat it.

## Initial level access

For MVP, the first level of each section should be available by default after registration.

All other normal levels should be locked.

Final tests should be locked until all 5 normal levels of the section are completed.

## Level unlocking

The next level is unlocked only after the previous level is completed with 0 mistakes.

If the user completes a level with one or more mistakes:

- save the attempt
- save the answers
- do not mark the level as completed
- do not unlock the next level

If the user completes a level with 0 mistakes:

- save the attempt
- save the answers
- mark the level as completed
- set `completed_at`
- unlock the next normal level in the same section
- if all 5 normal levels are completed, unlock the final test
- update streak

## Final test logic

A final test:

- belongs to a section
- has `is_final_test = true`
- does not introduce new words
- uses words from all 5 normal levels of the current section
- is unlocked only after all 5 normal levels in the section are completed
- is completed only with 0 mistakes

If the final test is completed with 0 mistakes:

- mark final test as completed
- update section progress
- update streak

If the final test has one or more mistakes:

- save attempt
- save answers
- do not mark final test as completed
- update streak

## Word learning

A word is considered learned when the user views it during the Learn word flow.

After the user finishes viewing all words of a level, Flutter calls:

```text
POST /api/levels/{levelId}/words/mark-learned
```

The backend should:

- check that the level is available or completed
- check that all word ids belong to the level
- create missing `user_word_progress` records
- avoid duplicate learned word records
- set `user_level_progress.words_learned = true`

Words from a final test are not marked as learned directly because final tests do not introduce new words.

## Level session

Flutter starts training by calling:

```text
GET /api/levels/{levelId}/session
```

The backend should return:

- level id
- level title
- section title
- final test flag
- exercises
- options for choice exercises
- correct answers for MVP client-side checking

For MVP, returning `correctAnswer` to Flutter is acceptable.

For a more secure version, the backend could verify answers again after completion.

## Level completion

Flutter completes training by calling:

```text
POST /api/levels/{levelId}/complete
```

The request contains all answers from the finished session.

Backend should:

1. Get current user id from JWT.
2. Check that the level exists and is available or completed.
3. Save a `level_attempts` row.
4. Save `user_answers` rows.
5. Count mistakes.
6. Increment `attempts_count`.
7. If mistakes count is 0, mark level as completed.
8. If mistakes count is 0, unlock the next level or final test.
9. Update streak.
10. Return result to Flutter.

## Mistakes logic

A level is successful only if:

```text
mistakesCount == 0
```

A level is failed if:

```text
mistakesCount > 0
```

A failed attempt should still be saved.

A failed attempt still counts as learning activity for streak.

## Answer normalization

Before checking input answers, normalize both user answer and correct answer.

Normalization steps:

1. Trim spaces at the beginning and end.
2. Convert to lowercase.
3. Replace repeated inner spaces with a single space.

Examples:

```text
"  APPLE  " -> "apple"
"  green   apple " -> "green apple"
```

Rules:

- Answer is correct only if normalized user answer fully matches normalized correct answer.
- Typos are not accepted.
- Multiple correct answers are not supported in MVP.

## Choice exercises

Choice exercises should have 4 options:

- 1 correct option
- 3 incorrect options

Options should be shuffled before returning to Flutter.

## Exercise types

Allowed exercise types:

- `picture_to_english_input`
- `english_to_russian_choice`
- `russian_to_english_choice`
- `russian_to_english_input`
- `english_to_russian_input`
- `audio_to_russian_choice`

## Progress calculation

Section progress is calculated by completed items.

Each section contains 6 progress items:

- 5 normal levels
- 1 final test

Formula:

```text
progressPercent = completedItems / totalItems * 100
```

Example:

```text
3 completed items / 6 total items * 100 = 50
```

## Learned words

A learned word:

- has a row in `user_word_progress`
- can be used in the daily test
- remains learned even if the user later fails the level

## Important constraints

Do not implement unless explicitly requested:

- typo-tolerant answer checking
- multiple correct answers
- spaced repetition algorithm
- complex adaptive difficulty
- backend saving of unfinished local attempts
