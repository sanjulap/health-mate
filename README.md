# HealthMate

HealthMate is a personal health and wellness tracker built with Flutter. It records daily steps, calories burned and water intake, stores everything locally with SQLite and shows progress against daily goals on a dashboard.

Built for the CI6330 Mobile Application Development module (Coursework 1).

## Features

- **Dashboard** – today's steps, calories and water totals with progress towards each daily goal, plus the current streak
- **Add / edit records** – date picker (no future dates) and validated numeric inputs
- **Record list** – all records, newest first, with edit and delete (with confirmation)
- **Search by date** – filter the list to a single day and clear the filter again
- **Daily goals** – change the steps, calories and water goals from the dashboard
- **Streak** – number of consecutive days that met at least one goal
- **Offline storage** – all data is kept on the device in SQLite, with sample records added on first launch

## Tech stack

| Package | Purpose |
| --- | --- |
| [provider](https://pub.dev/packages/provider) | State management (`ChangeNotifier`) |
| [sqflite](https://pub.dev/packages/sqflite) | Local SQLite database |
| [path](https://pub.dev/packages/path) | Building the database file path |
| [intl](https://pub.dev/packages/intl) | Date and number formatting |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | Icon set |
| [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) (dev) | Generating the app launcher icon |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) (dev) | Running database tests on desktop |
| [flutter_lints](https://pub.dev/packages/flutter_lints) (dev) | Lint rules |

## Architecture

The app follows an MVC-style layered architecture with Provider:

```
Views / Widgets  ->  HealthController  ->  HealthRepository  ->  DatabaseHelper  ->  SQLite
     (UI)            (ChangeNotifier)       (data access)          (sqflite)
```

- **Models** – `HealthRecord` and `GoalSettings`
- **Database** – `DatabaseHelper` creates the tables, seeds sample data and runs the CRUD queries
- **Repository** – `HealthRepository` sits between the controller and the database
- **Controller** – `HealthController` holds the app state, validation, filtering and dashboard calculations, and notifies the UI of changes
- **Views** – dashboard, record list and add/edit screens, built from reusable widgets

## Database

Database file: `healthmate.db`

**health_records**

| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER | Primary key, auto-increment |
| date | TEXT | `YYYY-MM-DD` |
| steps | INTEGER | Steps walked |
| calories | INTEGER | Calories burned |
| water | INTEGER | Water intake in ml |

**daily_goals**

| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER | Always `1` (single row) |
| steps_goal | INTEGER | Default 8000 |
| calories_goal | INTEGER | Default 500 |
| water_goal | INTEGER | Default 2500 ml |

## Project structure

```
lib/
├── main.dart
├── controllers/    health_controller.dart
├── database/       database_helper.dart
├── models/         health_record.dart, goal_settings.dart
├── repositories/   health_repository.dart
├── utils/          formatters.dart
├── views/          dashboard, record list, add/edit and navigation screens
└── widgets/        cards and the edit goals dialog
test/
├── controllers/    controller logic and validation
├── database/       DatabaseHelper against a real SQLite database
├── helpers/        in-memory fake repository
├── models/         HealthRecord mapping
├── utils/          formatters
└── widgets/        screen and user-flow tests
```

## Getting started

Requirements: Flutter SDK (Dart 3.13 or later) and an Android device or emulator.

```bash
git clone https://github.com/sanjulap/health-mate.git
cd health-mate
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```

To generate a coverage report:

```bash
flutter test --coverage
```

The tests cover the data model, formatters, controller logic (validation, CRUD, filtering, dashboard totals and streak), the database helper against a real SQLite database through `sqflite_common_ffi`, and widget tests for the main user flows.

## Building the APK

```bash
flutter build apk --release
```

The APK is created at `build/app/outputs/flutter-apk/app-release.apk`.
