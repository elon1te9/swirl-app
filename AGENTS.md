# AGENTS.md

## Project

This repository contains the swirl application.

swirl is an Android app for Russian-speaking beginners learning English words through sections, levels, word learning, exercises, daily tests, progress, and streaks.

## Important docs

Before starting any backend task, read:

- docs/00_PROJECT_OVERVIEW.md
- docs/01_BACKEND_ARCHITECTURE.md
- docs/02_DATABASE_SCHEMA.md
- docs/03_API_CONTRACT.md
- docs/06_LEARNING_LOGIC.md
- docs/08_SEED_DATA.md
- docs/11_BACKEND_TASKS.md

Before changing authentication, read:

- docs/04_AUTH_AND_SECURITY.md
- docs/03_API_CONTRACT.md
- docs/02_DATABASE_SCHEMA.md

Before changing level completion, progress, learned words, or unlocking logic, read:

- docs/06_LEARNING_LOGIC.md
- docs/07_DAILY_TEST_AND_STREAK.md
- docs/02_DATABASE_SCHEMA.md

Before changing seed data, read:

- docs/08_SEED_DATA.md

## Tech stack

Backend:

- ASP.NET Core Web API
- .NET 8
- Entity Framework Core
- PostgreSQL
- JWT Bearer Authentication
- Swagger / OpenAPI

Frontend:

- Flutter
- Dart
- Android

## Backend rules

- Use REST API.
- All user-specific endpoints must require JWT, except register, login, public avatar list, and static media.
- Do not return password hashes.
- Use request/response DTO models for API requests and responses, placed in `Requests` and `Responses`.
- Do not expose EF entities directly from controllers.
- Use async EF Core methods.
- Keep controllers thin.
- Put business logic into `Services`.
- Put service interfaces into `Interfaces`.
- Place EF entities in `Models`.
- Place seed logic in `Data`.
- Use PostgreSQL-compatible EF Core mappings.

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

## MVP constraints

Do not implement unless explicitly requested:

- admin panel UI
- payments
- subscriptions
- ads
- push notifications
- email confirmation
- leaderboard
- achievements
- dark theme
- iOS
- web app
- typo-tolerant answer checking

## Verification

After backend changes:

- run dotnet build
- run tests if they exist
- ensure Swagger starts
- ensure migrations are valid
