# Flutter simple architecture

This document fixes the simple Flutter architecture used in the student MVP.

The goal is to keep the app easy to read and extend. Do not add extra layers
just because they are common in large projects.

If this document conflicts with older Flutter documentation, follow this
document for the current MVP frontend code.

## Main rule

Use this flow for new features:

```text
Screen
  -> calls Controller
Controller
  -> calls Api
Api
  -> makes Dio request
Model
  -> parses JSON
```

## Folders

- `core` - shared infrastructure: Dio client, token storage, media URL helpers.
- `data/api` - classes that only send HTTP requests.
- `domain/models` - simple models created from backend JSON.
- `presentation/screens` - UI, form validation, loading state, error text.
- `presentation/state` - simple controllers and Riverpod providers.

## Riverpod

Use Riverpod only to create and pass dependencies:

```dart
final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
```

Do not use `Notifier`, `AsyncNotifier`, `StateNotifier`, repositories, or service
interfaces in early MVP stages unless there is a real repeated problem.

## Screens

Screen files may keep local UI state:

- text controllers;
- selected item id;
- `isLoading`;
- `errorMessage`;
- form validation.

This is okay for the MVP because it keeps the screen scenario visible in one
place.

## Controllers

A controller connects the screen to API/storage.

Example responsibilities:

- call an API method;
- save or delete a token;
- return a simple result to the screen;
- throw a short user-friendly error text when needed.

Controllers should not contain widget code.

## API classes

API classes only make requests and parse responses:

```text
AuthApi.login -> POST /api/auth/login -> AuthResponseModel
```

API classes should not navigate, show dialogs, or save tokens.

## Stage 2 auth note

The sign up screen does not show avatar selection in Stage 2.

During registration, Flutter sends a random predefined `avatarId` from the MVP
avatar set. The user can change avatar later from profile/settings.

## When to add a new layer

Add a new service/repository layer only if:

- the same logic is duplicated in several controllers;
- a controller becomes hard to read;
- tests become hard to write without separating logic.

If none of these happened, keep the simple structure.
