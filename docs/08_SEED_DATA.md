# Seed data

## Purpose

The backend must create initial MVP content automatically.

There is no admin panel UI in MVP, so seed data is required for the first launch.

Seed should create:

- avatars
- sections
- levels
- words
- exercises
- exercise options

## Seed location

Seed data may be stored:

- directly in C# seed code
- in JSON files inside the backend project
- in a combination of JSON files and C# import logic

For MVP, choose the simplest reliable implementation.

## Avatars

Create 3 predefined avatars for the MVP.

Example avatars:

| Name | Image URL |
|---|---|
| Avatar 1 | `/media/avatars/avatar_1.png` |
| Avatar 2 | `/media/avatars/avatar_2.png` |
| Avatar 3 | `/media/avatars/avatar_3.png` |

Rules:

- Avatars must have `is_active = true`.
- Flutter assigns one of the predefined avatars randomly during registration.
- Users may change avatar later through profile endpoint.

## Sections

Create 4 sections:

1. Food
2. Science
3. Health
4. Wardrobe

Recommended section media paths:

| Section | Image URL |
|---|---|
| Food | `/media/images/sections/food.png` |
| Science | `/media/images/sections/science.png` |
| Health | `/media/images/sections/health.png` |
| Wardrobe | `/media/images/sections/wardrobe.png` |

Rules:

- Sections must have `is_active = true`.
- Sections should have `sort_order`.
- Sections should be returned ordered by `sort_order`.

## Levels

Each section should support:

- 5 normal levels
- 1 final test

For MVP development, it is acceptable to seed fewer words and exercises at first, but the schema and business logic must support the full structure.

Example level structure for each section:

| Level number | Type | is_final_test |
|---|---|---|
| 1 | Normal level | false |
| 2 | Normal level | false |
| 3 | Normal level | false |
| 4 | Normal level | false |
| 5 | Normal level | false |
| 6 | Final test | true |

Rules:

- Normal levels introduce new words.
- Final tests do not introduce new words.
- Final tests use words from all normal levels in the same section.
- Levels should have `sort_order`.
- Levels should have CEFR level.
- For early MVP, most content may use `A1`.

## Words

Each normal level should eventually contain approximately 10 words.

For early MVP implementation, each level may contain 5-10 words.

Each word must contain:

- English word
- Russian translation
- transcription
- part of speech
- image URL
- audio URL
- CEFR level

Example word:

```json
{
  "english": "apple",
  "russian": "яблоко",
  "transcription": "ˈæpəl",
  "partOfSpeech": "noun",
  "imageUrl": "/media/images/words/apple.png",
  "audioUrl": "/media/audio/words/apple.mp3",
  "cefrLevel": "A1"
}
```

## Media paths

Use relative media paths.

Examples:

```text
/media/images/words/apple.png
/media/audio/words/apple.mp3
/media/avatars/avatar_1.png
/media/images/sections/food.png
```

Do not store absolute local file system paths in the database.

## Exercises

Normal level exercises should be created in advance in the database.

Each normal level should eventually contain approximately 20 exercises.

For early MVP, fewer exercises are acceptable, but the API and logic must support the full structure.

Allowed exercise types:

- `picture_to_english_input`
- `english_to_russian_choice`
- `russian_to_english_choice`
- `russian_to_english_input`
- `english_to_russian_input`
- `audio_to_russian_choice`

## Exercise options

Choice exercises must have answer options.

Choice exercise types:

- `english_to_russian_choice`
- `russian_to_english_choice`
- `audio_to_russian_choice`

Rules:

- Each choice exercise should have 4 options.
- Exactly 1 option should be correct.
- 3 options should be incorrect.
- Incorrect options may be selected from words of the same section or level.
- Options should be shuffled before returning to Flutter.

## Input exercises

Input exercise types:

- `picture_to_english_input`
- `russian_to_english_input`
- `english_to_russian_input`

Rules:

- Input exercises do not need `exercise_options`.
- Correct answer is stored in `exercises.correct_answer`.

## Suggested early MVP content

For the first backend implementation, it is enough to seed:

- 3 avatars
- 4 sections
- 2 normal levels per section
- 1 final test per section
- 5 words per normal level
- several exercises per level

However, the database schema and business logic must support:

- 5 normal levels per section
- 1 final test per section
- about 10 words per normal level
- about 20 exercises per normal level

## Initial user progress after registration

After successful registration, create initial progress for the user.

Recommended MVP rule:

- first level of each section is `available`
- all other normal levels are `locked`
- final tests are `locked`

Example:

```text
Food Level 1 -> available
Food Level 2 -> locked
Food Level 3 -> locked
Food Level 4 -> locked
Food Level 5 -> locked
Food Final Test -> locked
```

## Idempotency

Seed logic should be safe to run multiple times.

Recommended rules:

- do not duplicate sections if they already exist
- do not duplicate avatars if they already exist
- do not duplicate levels if they already exist
- do not duplicate words if they already exist
- do not duplicate exercises if they already exist

For MVP, this can be implemented with checks by title, level number, section, or another stable key.

## Out of scope for MVP

Do not implement unless explicitly requested:

- admin panel UI
- media upload UI
- user-uploaded avatars
- automatic import from external APIs
- paid content
- multilingual content management
