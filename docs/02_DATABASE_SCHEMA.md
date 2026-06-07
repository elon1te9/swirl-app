# Database schema

## General rules

Use PostgreSQL.

Use snake_case table and column names.

Use:

- `uuid` for user ids
- `serial` or identity integer ids for content tables
- `timestamp` for date and time values
- `date` for daily test dates and last activity date
- `text` for long strings and media URLs
- `varchar` for short required strings

Do not expose database entities directly from API controllers.

## users

Stores authentication data.

Columns:

- `id uuid primary key`
- `email varchar unique not null`
- `password_hash text not null`
- `created_at timestamp not null`
- `updated_at timestamp nullable`

Rules:

- `email` must be unique.
- Password must be stored only as a hash.
- Never return `password_hash` from API.

## user_profiles

Stores public user profile and streak data.

Columns:

- `id uuid primary key`
- `user_id uuid foreign key users(id)`
- `name varchar not null`
- `avatar_id int foreign key avatars(id)`
- `current_streak int default 0`
- `best_streak int default 0`
- `last_activity_date date nullable`
- `created_at timestamp not null`
- `updated_at timestamp nullable`

Rules:

- One user has one profile.
- Profile data must be visible only to the current authenticated user.

## avatars

Stores predefined avatars.

Columns:

- `id serial primary key`
- `name varchar not null`
- `image_url text not null`
- `is_active boolean default true`

Example image URL:

```text
/media/avatars/avatar_1.png
```

## sections

Stores thematic sections.

Columns:

- `id serial primary key`
- `title varchar not null`
- `description text nullable`
- `image_url text nullable`
- `sort_order int not null`
- `is_active boolean default true`
- `created_at timestamp not null`
- `updated_at timestamp nullable`

MVP sections:

- Food
- Science
- Health
- Wardrobe

## levels

Stores levels inside sections.

Columns:

- `id serial primary key`
- `section_id int foreign key sections(id)`
- `title varchar not null`
- `description text nullable`
- `level_number int not null`
- `cefr_level varchar not null`
- `is_final_test boolean default false`
- `sort_order int not null`
- `is_active boolean default true`
- `created_at timestamp not null`
- `updated_at timestamp nullable`

Rules:

- Each MVP section has 5 normal levels and 1 final test.
- Final test has `is_final_test = true`.
- Normal levels have `is_final_test = false`.
- Final test does not contain new words.

## words

Stores English words.

Columns:

- `id serial primary key`
- `level_id int foreign key levels(id)`
- `english varchar not null`
- `russian varchar not null`
- `transcription varchar nullable`
- `part_of_speech varchar nullable`
- `image_url text nullable`
- `audio_url text nullable`
- `cefr_level varchar not null`
- `is_active boolean default true`
- `created_at timestamp not null`
- `updated_at timestamp nullable`

Rules:

- A normal level contains approximately 10 words.
- Final tests do not have their own words.
- Final tests use words from all normal levels of the section.

Example media paths:

```text
/media/images/words/apple.png
/media/audio/words/apple.mp3
```

## exercises

Stores predefined exercise templates.

Columns:

- `id serial primary key`
- `level_id int foreign key levels(id)`
- `word_id int foreign key words(id)`
- `type varchar not null`
- `question_text text nullable`
- `correct_answer text not null`
- `sort_order int nullable`
- `is_active boolean default true`
- `created_at timestamp not null`
- `updated_at timestamp nullable`

Allowed `type` values:

- `picture_to_english_input`
- `english_to_russian_choice`
- `russian_to_english_choice`
- `russian_to_english_input`
- `english_to_russian_input`
- `audio_to_russian_choice`

Rules:

- A normal level contains approximately 20 exercises.
- Exercises are based on words from the current level.
- For MVP, normal level exercises should be stored in the database in advance.

## exercise_options

Stores answer options for choice exercises.

Columns:

- `id serial primary key`
- `exercise_id int foreign key exercises(id)`
- `option_text text not null`
- `is_correct boolean not null`
- `sort_order int nullable`

Rules:

- Choice exercises should have 4 options.
- Exactly 1 option should be correct.
- 3 options should be incorrect.
- Options should be shuffled before returning to Flutter.

## user_level_progress

Stores user progress for levels.

Columns:

- `id serial primary key`
- `user_id uuid foreign key users(id)`
- `level_id int foreign key levels(id)`
- `status varchar not null`
- `words_learned boolean default false`
- `completed_at timestamp nullable`
- `unlocked_at timestamp nullable`
- `attempts_count int default 0`

Allowed `status` values:

- `locked`
- `available`
- `completed`

Rules:

- The first level of each section should be available by default.
- The next level is unlocked only after the previous level is completed with 0 mistakes.
- The final test is unlocked only after all 5 normal levels in the section are completed.

Recommended unique constraint:

- `unique(user_id, level_id)`

## user_word_progress

Stores learned words for each user.

Columns:

- `id serial primary key`
- `user_id uuid foreign key users(id)`
- `word_id int foreign key words(id)`
- `learned_at timestamp not null`

Rules:

- A word is considered learned when the user views it in the Learn word flow.
- A learned word can be used in the daily test.

Required unique constraint:

- `unique(user_id, word_id)`

## level_attempts

Stores attempts to complete levels.

Columns:

- `id serial primary key`
- `user_id uuid foreign key users(id)`
- `level_id int foreign key levels(id)`
- `started_at timestamp not null`
- `completed_at timestamp nullable`
- `mistakes_count int default 0`
- `is_successful boolean default false`

Rules:

- Every completed level session should create a level attempt.
- A level attempt is successful only if `mistakes_count = 0`.
- Failed attempts should still be saved.

## user_answers

Stores user answers inside level attempts.

Columns:

- `id serial primary key`
- `attempt_id int foreign key level_attempts(id)`
- `exercise_id int foreign key exercises(id)`
- `user_answer text not null`
- `is_correct boolean not null`
- `answered_at timestamp not null`
- `time_spent_ms int nullable`

Rules:

- Store all answers submitted after level completion.
- Store correctness for each answer.
- Store time spent if Flutter sends it.

## daily_tests

Stores daily test attempts.

Columns:

- `id serial primary key`
- `user_id uuid foreign key users(id)`
- `test_date date not null`
- `started_at timestamp not null`
- `completed_at timestamp nullable`
- `total_questions int default 0`
- `correct_answers int default 0`
- `is_completed boolean default false`

Required unique constraint:

- `unique(user_id, test_date)`

Rules:

- Daily test date should be based on server date.
- Daily test result does not block section progress.

## daily_test_answers

Stores answers inside daily tests.

Columns:

- `id serial primary key`
- `daily_test_id int foreign key daily_tests(id)`
- `word_id int foreign key words(id)`
- `exercise_type varchar not null`
- `user_answer text not null`
- `is_correct boolean not null`
- `answered_at timestamp not null`

Rules:

- Daily test answers are linked to learned words.
- Daily test exercises may be generated dynamically.
