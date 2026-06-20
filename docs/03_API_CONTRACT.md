# API contract

## General rules

Base path:

```text
/api
```

Response format:

- All responses must be JSON.
- API must use DTOs for requests and responses.
- API must not expose EF Core entities directly.
- API must not return `password_hash`.

Authentication:

All endpoints require JWT Bearer token except:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/avatars`
- static media files from `/media`

Media files are served by backend as static files.

## Auth endpoints

### POST /api/auth/register

Registers a new user.

Request:

```json
{
  "name": "Vladimir",
  "email": "user@example.com",
  "password": "password123",
  "confirmPassword": "password123",
  "avatarId": 1
}
```

Response:

```json
{
  "accessToken": "jwt-token",
  "user": {
    "id": "uuid",
    "name": "Vladimir",
    "email": "user@example.com",
    "avatarUrl": "/media/avatars/avatar_1.png"
  }
}
```

Rules:

- Email must be unique.
- Password and confirmPassword must match.
- User profile must be created after successful registration.
- JWT access token must be returned after successful registration.
- First level of each section should be available for the new user by default.

### POST /api/auth/login

Logs in an existing user.

Request:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "accessToken": "jwt-token",
  "user": {
    "id": "uuid",
    "name": "Vladimir",
    "email": "user@example.com",
    "avatarUrl": "/media/avatars/avatar_1.png"
  }
}
```

Rules:

- Email and password are required.
- On invalid credentials, return an authorization error.
- Do not reveal whether email or password is incorrect.

### GET /api/auth/me

Returns the current authenticated user.

Response:

```json
{
  "id": "uuid",
  "name": "Vladimir",
  "email": "user@example.com",
  "avatarUrl": "/media/avatars/avatar_1.png"
}
```

Rules:

- Requires JWT.
- Returns only the current authenticated user.

## Profile endpoints

### GET /api/profile

Returns current user's profile and progress summary.

Response:

```json
{
  "name": "Vladimir",
  "avatarUrl": "/media/avatars/avatar_1.png",
  "currentStreak": 4,
  "bestStreak": 7,
  "lastActivityDate": "2026-05-13",
  "learnedWordsCount": 45,
  "completedLevelsCount": 8,
  "sectionsProgress": [
    {
      "sectionId": 1,
      "title": "Food",
      "progressPercent": 50
    }
  ]
}
```

Rules:

- Requires JWT.
- Must return data only for the current authenticated user.

### PUT /api/profile/avatar

Changes current user's avatar.

Request:

```json
{
  "avatarId": 2
}
```

Response:

```json
{
  "avatarUrl": "/media/avatars/avatar_2.png"
}
```

Rules:

- Requires JWT.
- Avatar must exist and be active.

## Avatar endpoints

### GET /api/avatars

Returns available predefined avatars.

Response:

```json
[
  {
    "id": 1,
    "name": "Avatar 1",
    "imageUrl": "/media/avatars/avatar_1.png"
  }
]
```

Rules:

- Return only active avatars.
- This endpoint is public.

## Sections endpoints

### GET /api/sections

Returns all active sections with current user's progress.

Response:

```json
[
  {
    "id": 1,
    "title": "Food",
    "description": "Words about food and drinks",
    "imageUrl": "/media/images/sections/food.png",
    "progressPercent": 40,
    "completedLevels": 2,
    "totalLevels": 6
  }
]
```

Rules:

- Requires JWT.
- Sort by `sort_order`.
- Progress is calculated as `completed_items / total_items * 100`.
- In MVP, total items per section are 6: 5 normal levels and 1 final test.

### GET /api/sections/{sectionId}

Returns detailed section information.

Response:

```json
{
  "id": 1,
  "title": "Food",
  "description": "Words about food and drinks",
  "imageUrl": "/media/images/sections/food.png",
  "progressPercent": 40,
  "completedLevels": 2,
  "totalLevels": 6
}
```

Rules:

- Requires JWT.
- Section must exist and be active.

## Levels endpoints

### GET /api/sections/{sectionId}/levels

Returns levels of a section with current user's level statuses.

Response:

```json
[
  {
    "id": 1,
    "sectionId": 1,
    "title": "Food Level 1",
    "levelNumber": 1,
    "cefrLevel": "A1",
    "description": "Basic food words",
    "wordsCount": 10,
    "exercisesCount": 20,
    "isFinalTest": false,
    "status": "completed",
    "completedAt": "2026-05-13T12:30:00"
  },
  {
    "id": 2,
    "sectionId": 1,
    "title": "Food Level 2",
    "levelNumber": 2,
    "cefrLevel": "A1",
    "description": "More food words",
    "wordsCount": 10,
    "exercisesCount": 20,
    "isFinalTest": false,
    "status": "available",
    "completedAt": null
  },
  {
    "id": 6,
    "sectionId": 1,
    "title": "Food Final Test",
    "levelNumber": 6,
    "cefrLevel": "A1",
    "description": "Final test for Food section",
    "wordsCount": 0,
    "exercisesCount": 30,
    "isFinalTest": true,
    "status": "locked"
  }
]
```

Allowed status values:

- `locked`
- `available`
- `completed`

Rules:

- Requires JWT.
- Return only active levels.
- Sort by `sort_order`.
- Locked levels cannot be started.

### GET /api/levels/{levelId}

Returns level details.

Response:

```json
{
  "id": 1,
  "sectionId": 1,
  "sectionTitle": "Food",
  "title": "Food Level 1",
  "levelNumber": 1,
  "cefrLevel": "A1",
  "description": "Basic food words",
  "wordsCount": 10,
  "exercisesCount": 20,
  "isFinalTest": false,
  "status": "available",
  "wordsLearned": false
}
```

Rules:

- Requires JWT.
- Must include current user's level status.
- If level is locked, Flutter should not allow training.

### GET /api/levels/{levelId}/words

Returns words for the Learn word screen.

Response:

```json
[
  {
    "id": 1,
    "english": "apple",
    "russian": "яблоко",
    "transcription": "ˈæpəl",
    "partOfSpeech": "noun",
    "imageUrl": "/media/images/words/apple.png",
    "audioUrl": "/media/audio/words/apple.mp3"
  }
]
```

Rules:

- Requires JWT.
- Level must be available or completed.
- For final tests, response may be empty because final tests do not introduce new words.

### POST /api/levels/{levelId}/words/mark-learned

Marks level words as learned for the current user.

Request:

```json
{
  "wordIds": [1, 2, 3, 4, 5]
}
```

Response:

```json
{
  "levelId": 1,
  "wordsLearned": true,
  "learnedWordsCount": 5
}
```

Rules:

- Requires JWT.
- Level must be available or completed.
- Word ids must belong to the specified level.
- Create records in `user_word_progress`.
- Do not duplicate already learned words.
- Set `user_level_progress.words_learned = true`.

## Exercise endpoints

### GET /api/levels/{levelId}/session

Returns full level session data for training.

Response:

```json
{
  "levelId": 1,
  "title": "Food Level 1",
  "sectionTitle": "Food",
  "isFinalTest": false,
  "exercises": [
    {
      "id": 101,
      "type": "english_to_russian_choice",
      "questionText": "apple",
      "questionImageUrl": null,
      "questionAudioUrl": null,
      "correctAnswer": "яблоко",
      "options": [
        "яблоко",
        "молоко",
        "хлеб",
        "вода"
      ]
    }
  ]
}
```

Rules:

- Requires JWT.
- Level must be available or completed.
- Locked levels must not return a training session.
- For MVP, `correctAnswer` may be returned to Flutter.
- Choice options should be shuffled.
- Flutter should complete the session locally and send final result only after all exercises are completed.

### POST /api/levels/{levelId}/complete

Completes a level attempt.

Request:

```json
{
  "answers": [
    {
      "exerciseId": 101,
      "userAnswer": "яблоко",
      "isCorrect": true,
      "timeSpentMs": 4200
    }
  ]
}
```

Success response:

```json
{
  "isLevelCompleted": true,
  "mistakesCount": 0,
  "openedNextLevelId": 2,
  "currentStreak": 5,
  "bestStreak": 7
}
```

Failed response:

```json
{
  "isLevelCompleted": false,
  "mistakesCount": 3,
  "openedNextLevelId": null,
  "currentStreak": 5,
  "bestStreak": 7
}
```

Rules:

- Requires JWT.
- Level must be available or completed.
- Save `level_attempts`.
- Save `user_answers`.
- Increment `attempts_count`.
- If `mistakesCount = 0`, mark level as completed.
- If `mistakesCount = 0`, unlock next level in the same section.
- If all 5 normal levels are completed, unlock final test.
- If `mistakesCount > 0`, do not mark level completed and do not unlock next level.
- Update streak because a completed attempt is a learning activity.

## Daily test endpoints

### GET /api/daily-test

Returns daily test for the current user.

Available response:

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

Unavailable response:

```json
{
  "date": "2026-05-13",
  "isAvailable": false,
  "reason": "Not enough learned words"
}
```

Rules:

- Requires JWT.
- Daily test is available only if the user has at least 5 learned words.
- Daily test is generated from current user's learned words.
- Use server date.
- Daily test result does not block section progress.

### POST /api/daily-test/complete

Completes current user's daily test.

Request:

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

Response:

```json
{
  "completed": true,
  "correctAnswers": 18,
  "totalAnswers": 20,
  "currentStreak": 5,
  "bestStreak": 7
}
```

Rules:

- Requires JWT.
- Save `daily_tests`.
- Save `daily_test_answers`.
- Update streak.
- Do not change level or section progress.

## Error responses

Use a clear JSON error format.

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

Recommended HTTP statuses:

- `400 Bad Request` for validation errors
- `401 Unauthorized` for missing or invalid JWT
- `403 Forbidden` for access to another user's data
- `404 Not Found` for missing resources
- `409 Conflict` for duplicate email or conflicting state
- `500 Internal Server Error` for unexpected errors
