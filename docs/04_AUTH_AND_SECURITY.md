# Auth and security

## Authentication approach

Use JWT Bearer Authentication.

The backend must issue a JWT access token after:

- successful registration
- successful login

Flutter stores the JWT token locally and sends it in the `Authorization` header:

```text
Authorization: Bearer jwt-token
```

## Public endpoints

The following endpoints are public:

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/avatars`
- static media files from `/media`

All other user-specific endpoints must require JWT.

## User identity

The backend must get the current user id from JWT claims.

Do not accept `userId` from client requests for user-specific actions.

Examples of user-specific actions:

- getting profile
- changing avatar
- getting sections with progress
- getting levels with statuses
- marking words as learned
- completing a level
- getting daily test
- completing daily test

## Password storage

Never store plain text passwords.

Store only password hashes in the database.

Recommended approach for MVP:

- use a password hashing service
- hash password before saving user
- verify login password against the stored hash

The API must never return:

- `password`
- `password_hash`
- password-related internal data

## Registration rules

Registration request fields:

- `name`
- `email`
- `password`
- `confirmPassword`
- `avatarId`

Validation rules:

- name is required
- email is required
- email must have valid format
- password is required
- confirmPassword is required
- password and confirmPassword must match
- avatarId must reference an active avatar
- email must be unique

After successful registration:

- create user
- create user profile
- assign selected avatar
- create initial level progress
- make first level of each section available by default
- return JWT access token
- return current user DTO

Email confirmation is not required in MVP.

## Login rules

Login request fields:

- `email`
- `password`

Validation rules:

- email is required
- password is required

On successful login:

- return JWT access token
- return current user DTO

On failed login:

- return authentication error
- do not reveal whether email or password is wrong

Recommended error message:

```text
Invalid email or password
```

## JWT rules

JWT should include enough data to identify the current user.

Recommended claims:

- user id
- email

JWT should not include sensitive data.

Do not include:

- password hash
- internal security data

## Authorization rules

Users can access only their own data.

The backend must prevent access to another user's:

- profile
- progress
- learned words
- level attempts
- answers
- daily tests
- daily test answers

For all user-specific queries, filter by current authenticated user id.

## Static media

Static media files are public.

Media paths are stored in the database as relative paths, for example:

```text
/media/images/words/apple.png
/media/audio/words/apple.mp3
/media/avatars/avatar_1.png
```

Do not store absolute local file system paths in the database.

## CORS

Configure CORS so Flutter development builds can access the backend API.

For MVP, a permissive development CORS policy is acceptable.

Before production, CORS should be restricted to known clients.

## Error handling

Do not expose internal exceptions to clients.

Use clear JSON error responses.

Recommended format:

```json
{
  "error": {
    "code": "unauthorized",
    "message": "Authentication is required"
  }
}
```

## MVP security constraints

Do not implement unless explicitly requested:

- email confirmation
- password reset by email
- refresh tokens
- two-factor authentication
- OAuth login
- roles and permissions UI
- admin panel UI

## Important security rules

- Never return password hashes.
- Never trust user id from request body.
- Always use current user id from JWT.
- Always check resource ownership.
- Use HTTPS in real deployment.
- Keep JWT secret outside source code.
- Do not commit real secrets to git.
