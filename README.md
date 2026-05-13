# swirl

swirl is an Android application for Russian-speaking beginners who learn English words through thematic sections, levels, exercises, daily tests, progress, and streaks.

## Tech stack

Backend:

- ASP.NET Core Web API
- .NET 8
- PostgreSQL
- Entity Framework Core
- JWT Bearer Authentication
- Swagger / OpenAPI

Frontend:

- Flutter
- Dart
- Android

## Main MVP features

- registration
- login
- JWT authentication
- profile
- avatar selection
- home page
- sections
- level map
- word learning
- exercises
- level completion
- user progress
- daily test
- streak
- backend media storage

## Documentation

Project documentation is stored in `/docs`.

Recommended reading order:

1. `docs/00_PROJECT_OVERVIEW.md` — product overview and MVP scope
2. `docs/01_BACKEND_ARCHITECTURE.md` — ASP.NET Core API architecture
3. `docs/02_DATABASE_SCHEMA.md` — PostgreSQL database schema
4. `docs/03_API_CONTRACT.md` — REST API endpoints and request/response contracts
5. `docs/04_AUTH_AND_SECURITY.md` — authentication and security rules
6. `docs/04_FRONTEND_ARCHITECTURE.md` — Flutter app architecture
7. `docs/05_LEARNING_LOGIC.md` — levels, exercises, progress, and word learning logic
8. `docs/06_DAILY_TEST_AND_STREAK.md` — daily test and streak logic
9. `docs/07_SEED_DATA.md` — MVP seed content rules
10. `docs/08_ERROR_HANDLING.md` — API error format and error handling rules
11. `docs/09_CODE_STYLE.md` — backend and general code style
12. `docs/10_BACKEND_TASKS.md` — backend implementation stages
13. `docs/11_FLUTTER_TASKS.md` — Flutter implementation stages
14. `docs/12_UI_UX_GUIDE.md` — UI/UX design guide
15. `docs/12_OPEN_QUESTIONS.md` — open product and technical questions
16. `docs/DECISIONS.md` — confirmed project decisions

## MVP constraints

The MVP does not include:

- iOS
- web version
- monetization
- subscriptions
- ads
- push notifications
- email confirmation
- admin panel UI
- leaderboard
- achievements
- dark theme
- advanced analytics
- offline-first mode
