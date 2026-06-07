# Backend architecture

## Stack

Backend stack:

- ASP.NET Core Web API
- .NET 8
- Entity Framework Core
- PostgreSQL
- JWT Bearer Authentication
- Swagger / OpenAPI

## Suggested project structure

Use this structure for the backend project:

```text
Swirl.Api/
  Properties/
  Controllers/
  Data/
  Hubs/
  Interfaces/
  Migrations/
  Models/
  Requests/
  Responses/
  Services/
  appsettings.json
  Program.cs
  Swirl.Api.http
```

## Layers

### Controllers

Controllers should:

- receive HTTP requests
- validate request models
- get current user id from JWT when needed
- call services
- return DTO responses from `Responses`

Controllers should not contain complex business logic.

### Interfaces

Interfaces should contain service contracts.

Use `Interfaces` for:

- authentication service contracts
- profile service contracts
- sections and levels service contracts
- word learning service contracts
- level completion service contracts
- daily test service contracts
- streak service contracts

### Services

Services should contain business logic:

- registration and login
- profile logic
- sections and levels progress
- word learning
- level completion
- next level unlocking
- daily test generation
- streak update

### Data

Data layer should contain:

- AppDbContext
- EF Core configuration
- database connection setup
- seed logic or simple seed helper classes

### Migrations

`Migrations` should contain EF Core migrations only.

### Models

`Models` should contain:

- database entities

API controllers must not expose EF entities directly.

### Requests

`Requests` should contain API request DTO models.

### Responses

`Responses` should contain API response DTO models.

All API responses should return response DTO models, not EF entities.

### Hubs

`Hubs` is an optional folder for SignalR.

Do not use SignalR in MVP unless explicitly requested.

## Static media

The backend serves static files from:

```text
wwwroot/media
```

Recommended structure:

```text
wwwroot/
  media/
    images/
      sections/
      words/
    audio/
      words/
    avatars/
```

Database should store relative media paths, for example:

```text
/media/images/words/apple.png
/media/audio/words/apple.mp3
/media/avatars/avatar_1.png
```

## Authentication

Use JWT Bearer Authentication.

All user-specific endpoints must require JWT, except:

- POST /api/auth/register
- POST /api/auth/login
- static media files
- GET /api/avatars

The backend must never return password hashes.

## Business logic placement

Do not put the following logic into controllers:

- password hashing
- JWT generation
- level unlocking
- streak calculation
- daily test generation
- answer normalization
- progress calculation

Put this logic into services.

Service interfaces should be placed in `Interfaces`.

## Database rules

Use PostgreSQL-compatible EF Core mappings.

Use:

- uuid for users
- serial or identity integer ids for content tables
- timestamp for datetime values
- date for last activity date and daily test date

## Async rules

Use async methods for database operations.

Use CancellationToken where practical.

## API rules

- Use REST API.
- Use JSON request and response bodies.
- Use clear request/response model names.
- Validate user ownership for all user-specific resources.
- Do not allow users to access or change progress of another user.
- Do not expose password_hash.
- Do not expose internal implementation details in error responses.

## Folder rules

- Do not create folders `DTOs`, `Repositories`, `Mapping`, `Middleware`, `Extensions`, `Seed` unless explicitly requested later.
- Place seed logic in `Data`.
- Place EF entities in `Models`.
- Place request DTO models in `Requests`.
- Place response DTO models in `Responses`.

## MVP architecture principle

The app must not send a request for every exercise.

Correct level flow:

1. Flutter requests full level session from backend.
2. Backend returns level data and all exercises.
3. Flutter runs the exercise session locally.
4. Flutter sends all answers after the level is finished.
5. Backend saves attempt, answers, progress, unlocks next level if needed, and updates streak.
