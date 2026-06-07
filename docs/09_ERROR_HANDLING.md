# Error handling

## Goal

The backend should return predictable and clear JSON error responses.

Flutter should be able to show understandable messages to the user and handle errors consistently.

## General error response format

Use this format for API errors:

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

## Minimal error response

If there are no details, use this format:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Authentication is required"
  }
}
```

## Error fields

### code

A stable machine-readable error code.

Examples:

- `validation_error`
- `unauthorized`
- `forbidden`
- `not_found`
- `conflict`
- `invalid_credentials`
- `level_locked`
- `not_enough_learned_words`
- `internal_error`

### message

A short human-readable message.

The message should be safe to show to the user.

### details

Optional object with field-level validation errors or additional safe context.

Do not include sensitive internal details.

## HTTP status codes

Use standard HTTP status codes.

### 400 Bad Request

Use for validation errors and invalid request body.

Examples:

- missing required field
- invalid email format
- password and confirmPassword do not match
- invalid avatar id
- word ids do not belong to the level

### 401 Unauthorized

Use when authentication is missing or invalid.

Examples:

- missing JWT token
- invalid JWT token
- expired JWT token

### 403 Forbidden

Use when the user is authenticated but cannot access the resource.

Examples:

- user tries to access another user's data
- user tries to modify another user's progress

### 404 Not Found

Use when a requested resource does not exist or is inactive.

Examples:

- section not found
- level not found
- word not found
- avatar not found

### 409 Conflict

Use for conflicting state.

Examples:

- email already exists
- level is locked
- daily test already completed if repeated completion is not allowed

### 500 Internal Server Error

Use for unexpected backend errors.

Do not expose exception details to the client.

## Recommended error codes

### validation_error

Use for request validation problems.

Example:

```json
{
  "error": {
    "code": "validation_error",
    "message": "Validation failed",
    "details": {
      "password": ["Password is required"],
      "confirmPassword": ["Password and confirmPassword must match"]
    }
  }
}
```

### invalid_credentials

Use for failed login.

Example:

```json
{
  "error": {
    "code": "invalid_credentials",
    "message": "Invalid email or password"
  }
}
```

Do not reveal whether email or password is incorrect.

### email_already_exists

Use for duplicate registration email.

Example:

```json
{
  "error": {
    "code": "email_already_exists",
    "message": "Email is already registered"
  }
}
```

### unauthorized

Use for missing or invalid authentication.

Example:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Authentication is required"
  }
}
```

### forbidden

Use when current user cannot access the requested resource.

Example:

```json
{
  "error": {
    "code": "forbidden",
    "message": "You do not have access to this resource"
  }
}
```

### not_found

Use for missing resources.

Example:

```json
{
  "error": {
    "code": "not_found",
    "message": "Resource not found"
  }
}
```

### level_locked

Use when user tries to start a locked level.

Example:

```json
{
  "error": {
    "code": "level_locked",
    "message": "This level is locked"
  }
}
```

### not_enough_learned_words

Use when daily test is not available.

Example:

```json
{
  "error": {
    "code": "not_enough_learned_words",
    "message": "Learn more words to unlock the daily test"
  }
}
```

Note: `GET /api/daily-test` may return a normal unavailable response instead of an error:

```json
{
  "date": "2026-05-13",
  "isAvailable": false,
  "reason": "Not enough learned words"
}
```

### internal_error

Use for unexpected errors.

Example:

```json
{
  "error": {
    "code": "internal_error",
    "message": "Something went wrong"
  }
}
```

## Validation rules

Validate request DTOs before business logic.

Important validation examples:

Registration:

- name is required
- email is required
- email format must be valid
- password is required
- confirmPassword is required
- password and confirmPassword must match
- avatarId must reference active avatar
- email must be unique

Login:

- email is required
- password is required

Change avatar:

- avatarId is required
- avatar must exist and be active

Mark learned words:

- wordIds must not be empty
- all wordIds must belong to the level
- level must be available or completed

Complete level:

- answers must not be empty
- exerciseId must belong to the level
- level must be available or completed
- locked levels cannot be completed

Complete daily test:

- answers must not be empty
- wordId must belong to learned words of current user

## Security rules

Error responses must not expose:

- stack traces
- database connection strings
- SQL queries
- JWT secrets
- password hashes
- internal exception messages
- file system paths

## Logging

The backend may log internal exception details on the server side.

Do not return internal exception details to Flutter.

## Flutter expectations

Flutter should be able to:

- show validation messages under form fields
- redirect to login on `401`
- show a locked state on `level_locked`
- show a retry button on network or server errors
- show unavailable daily test state if not enough learned words

## Out of scope for MVP

Do not implement unless explicitly requested:

- localized backend error messages
- complex error tracking service
- Sentry integration
- automatic retry policies
- detailed analytics for errors
