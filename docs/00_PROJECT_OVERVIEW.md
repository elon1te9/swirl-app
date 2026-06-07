# Project overview

swirl is a mobile Android app for Russian-speaking users who are beginning to learn English.

The MVP focuses on learning English words, not grammar, texts, speaking, or advanced language practice.

## Product goal

Create a simple, visually friendly, and understandable app that helps beginner users learn English words through thematic sections, levels, word cards, exercises, daily tests, progress, and streaks.

## Target audience

Russian-speaking users of any age who are starting to learn English from zero or near-zero level.

The app is not focused on:

- advanced grammar
- complex texts
- speaking practice
- professional language learning

The main MVP focus is vocabulary learning.

## Main user flow

1. User opens the app.
2. App checks JWT token.
3. User registers or logs in.
4. User sees the Home page.
5. User opens Sections.
6. User selects a section.
7. User opens a level.
8. User learns new words.
9. User completes exercises.
10. If there are 0 mistakes, the level is completed.
11. The next level is unlocked.
12. Progress and streak are updated.

## MVP sections

The MVP contains 4 sections:

- Food
- Science
- Health
- Wardrobe

Each section contains:

- 5 normal levels
- 1 final test

## Level structure

Each normal level contains approximately:

- 10 new words
- 20 exercises

A final test contains no new words. It uses words from all normal levels of the current section.

## MVP features

The MVP must include:

- registration
- login
- JWT authentication
- profile
- automatic avatar assignment during registration
- avatar change from profile later in MVP
- home page
- sections
- level map
- word learning
- exercises
- successful and failed level result
- progress saving
- next level unlocking
- daily test
- streak
- backend API
- PostgreSQL database
- media served from backend

## Out of scope for MVP

Do not implement unless explicitly requested:

- Google Play publication
- iOS version
- web version
- monetization
- subscriptions
- ads
- push notifications
- email notifications
- admin panel UI
- leaderboard
- achievements
- internal currency
- user levels
- automatic English level detection
- user-uploaded avatars
- dark theme
- advanced analytics
- full offline-first mode
- typo-tolerant answer checking

## Important product principle

The app should feel fast during exercises.

Flutter should receive a full level session from the backend with one request, complete exercises locally, and send the final result to the backend after the level is finished.
