# Code style

## General principles

Code should be simple, readable, and suitable for an MVP.

Prefer clarity over cleverness.

Avoid unnecessary abstractions unless they make the project easier to maintain.

## Backend language and framework

Use:

- C#
- ASP.NET Core Web API
- .NET 8
- Entity Framework Core
- PostgreSQL

## Naming rules

Use PascalCase for:

- classes
- records
- DTOs
- services
- controllers
- public properties
- public methods

Use camelCase for:

- local variables
- method parameters
- private fields when not using underscore style

Use snake_case for:

- database table names
- database column names

## Project structure

Recommended backend structure:

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

Structure rules:

- `Controllers` - HTTP API controllers.
- `Data` - `AppDbContext`, EF Core configuration, database setup, seed logic.
- `Models` - database entities.
- `Requests` - API request DTO models.
- `Responses` - API response DTO models.
- `Interfaces` - service interfaces.
- `Services` - business logic services.
- `Migrations` - EF Core migrations.
- `Hubs` - optional folder for SignalR; do not use it in MVP unless explicitly requested.
- Do not create folders `DTOs`, `Repositories`, `Mapping`, `Middleware`, `Extensions`, `Seed` unless explicitly requested later.

## Controllers

Controllers should be thin.

Controllers should:

- receive HTTP requests
- validate basic request data
- get current user id from JWT when needed
- call services
- accept request DTO models from `Requests`
- return response DTO models from `Responses`

Controllers should not contain:

- password hashing logic
- JWT generation logic
- level unlocking logic
- streak calculation logic
- daily test generation logic
- complex database queries

## Services

Services should contain business logic.

Use services for:

- authentication
- profile operations
- content queries
- progress calculation
- word learning
- level completion
- next level unlocking
- daily test generation
- streak updates

## Interfaces

Place service interfaces in `Interfaces`.

Use interfaces for:

- authentication services
- profile services
- content services
- progress services
- daily test services
- streak services

## Models

Place EF entities in `Models`.

Do not expose EF Core entities directly from controllers.

Entities should represent database tables.

Entities should not contain complex business logic.

Use navigation properties only where they make queries easier and do not create unnecessary complexity.

## Requests

Place API request DTO models in `Requests`.

Recommended request model naming:

```text
RegisterRequest
LoginRequest
CompleteLevelRequest
CompleteDailyTestRequest
```

## Responses

Place API response DTO models in `Responses`.

Recommended response model naming:

```text
AuthResponse
CurrentUserResponse
ProfileResponse
SectionResponse
LevelResponse
WordResponse
LevelSessionResponse
ExerciseResponse
CompleteLevelResponse
DailyTestResponse
CompleteDailyTestResponse
```

## Async

Use async EF Core methods for database operations.

Examples:

```csharp
await dbContext.Users.FirstOrDefaultAsync(...);
await dbContext.SaveChangesAsync();
await dbContext.Sections.ToListAsync();
```

Use `CancellationToken` where practical.

## Error handling

Use consistent JSON error responses.

Do not expose internal exception details to API clients.

Do not return:

- stack traces
- SQL queries
- connection strings
- JWT secrets
- password hashes
- internal file system paths

## Security

Important rules:

- never store plain text passwords
- never return password hashes
- never trust user id from request body
- always get current user id from JWT
- always filter user-specific data by current user id
- validate resource ownership
- keep secrets outside source code

## Database

Use EF Core migrations.

Use PostgreSQL-compatible mappings.

Use snake_case table and column names.

Keep migrations in `Migrations`.

Place seed logic in `Data` or in a simple helper class inside `Data`.

Recommended ids:

- `Guid` for users
- `int` for content tables
- `DateTime` for timestamps
- `DateOnly` or date-compatible mapping for date-only values if practical

## API

Use REST-style endpoints.

Use JSON request and response bodies.

Use meaningful HTTP status codes.

Use response DTO models for all responses.

Do not return database entities directly.

## Comments

Add comments only when they explain non-obvious business logic.

Avoid comments that simply repeat the code.

Good comment example:

```csharp
// Failed attempts still update streak because they count as learning activity.
```

Bad comment example:

```csharp
// Increment attempts count by one.
```

## MVP constraints

Do not add unnecessary production complexity unless explicitly requested.

Do not implement unless explicitly requested:

- refresh tokens
- email confirmation
- password reset emails
- admin panel UI
- payment logic
- subscription logic
- push notifications
- advanced analytics
- complex role system
- typo-tolerant answer checking
- spaced repetition algorithm

## Verification

After backend changes:

- run `dotnet build`
- run tests if tests exist
- ensure Swagger can start
- ensure migrations are valid
- ensure API endpoints follow documented contracts

## Codex behavior

When implementing a task:

1. Read the relevant docs first.
2. Make the smallest reasonable set of changes.
3. Do not implement unrelated features.
4. Keep code consistent with existing structure.
5. Prefer simple MVP-ready solutions.
6. Report what was changed.
7. Report build or test results.
