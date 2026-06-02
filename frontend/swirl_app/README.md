# Swirl Flutter app

This folder contains the Android Flutter client for Swirl.

## Architecture

Use the simple MVP flow:

```text
Screen -> Controller -> Api/Storage
Api -> Dio request
Model -> parses JSON
```

Riverpod is used mostly for dependency providers such as Dio, API classes,
token storage, and controllers. Keep form fields, loading flags, selected ids,
and error text inside `StatefulWidget` screens when that keeps the code easier
to read.

## Run

Install dependencies:

```bash
flutter pub get
```

Run on Android emulator with the local backend:

```bash
flutter run --dart-define=SWIRL_BACKEND_ORIGIN=http://10.0.2.2:5122
```

Run checks:

```bash
flutter analyze
flutter test
```

## Auth note

Stage 2 registration does not show avatar selection. The app sends a random
predefined `avatarId` during registration, and the user can change avatar later
from profile/settings.
