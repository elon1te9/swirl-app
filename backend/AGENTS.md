# Backend AGENTS.md

This folder contains the ASP.NET Core backend for the swirl API.

## Important docs

Before making backend changes, read:

- `../AGENTS.md`
- `../docs/00_PROJECT_OVERVIEW.md`
- `../docs/01_BACKEND_ARCHITECTURE.md`
- `../docs/02_DATABASE_SCHEMA.md`
- `../docs/03_API_CONTRACT.md`
- `../docs/04_AUTH_AND_SECURITY.md`
- `../docs/06_LEARNING_LOGIC.md`
- `../docs/07_DAILY_TEST_AND_STREAK.md`
- `../docs/08_SEED_DATA.md`
- `../docs/09_ERROR_HANDLING.md`
- `../docs/10_CODE_STYLE.md`
- `../docs/11_BACKEND_TASKS.md`

## Backend stack

Use:

- ASP.NET Core Web API
- .NET 8
- Entity Framework Core
- PostgreSQL
- JWT Bearer Authentication
- Swagger / OpenAPI

## Project structure

Use this simplified ASP.NET Core API structure:

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

Folder responsibilities:

- `Controllers` — HTTP API controllers.
- `Data` — `AppDbContext`, EF Core configuration, database setup, seed logic.
- `Models` — database entities.
- `Requests` — API request DTO models.
- `Responses` — API response DTO models.
- `Interfaces` — service interfaces.
- `Services` — business logic services.
- `Migrations` — EF Core migrations.
- `Hubs` — optional folder for SignalR; do not use it in MVP unless explicitly requested.

Do not create folders:

- `DTOs`
- `Repositories`
- `Mapping`
- `Middleware`
- `Extensions`
- `Seed`

unless explicitly requested later.

## Backend rules

- Use REST API.
- Use JSON request and response bodies.
- Use request models from `Requests` and response models from `Responses`.
- Do not expose EF Core entities directly from controllers.
- Keep controllers thin.
- Put business logic in `Services`.
- Put service interfaces in `Interfaces`.
- Put `AppDbContext` and seed logic in `Data`.
- Use async EF Core methods.
- Use PostgreSQL-compatible mappings.
- Use current user id from JWT for user-specific operations.
- Do not accept `userId` from request body for user-specific operations.
- Do not return password hashes.
- Validate resource ownership.

## Auth rules

Public endpoints:

- `POST /api/auth/register`
- `POST /api/auth/login`
- static media files from `/media`

All other user-specific endpoints must require JWT.

`GET /api/avatars` is public.

## MVP constraints

Do not implement unless explicitly requested:

- refresh tokens
- email confirmation
- password reset
- admin panel UI
- payments
- subscriptions
- ads
- push notifications
- leaderboard
- achievements
- dark theme
- typo-tolerant answer checking
- spaced repetition algorithm

## Commands

Build:

```bash
dotnet build
```

Run API:

```bash
dotnet run --project Swirl.Api
```

Create migration:

```bash
dotnet ef migrations add InitialCreate --project Swirl.Api
```

Update database:

```bash
dotnet ef database update --project Swirl.Api
```

## Verification

After each backend task:

- run `dotnet build`
- run tests if tests exist
- ensure Swagger can start
- ensure migrations are valid if database models changed
- ensure API contract matches docs
- report what was changed
- report build or test result

## Task workflow

When asked to implement a backend stage:

1. Read the relevant docs.
2. Implement only the requested stage.
3. Do not implement unrelated features.
4. Keep code simple and MVP-ready.
5. Use the documented project structure.
6. Run verification commands.
7. Summarize changes.
