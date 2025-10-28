# BMI Calculator (untitled)

A small Flutter BMI calculator with persistent history using SQLite (sqflite).

Features
- Measure BMI from height (cm, m, ft) and weight (kg, lb).
- Gender selection and visual category feedback.
- Save BMI calculations to local SQLite database (or in-memory on web).
- View and clear saved history.

Units
- Height supported units: cm (centimeters), m (meters), ft (feet).
  - Internal storage is in centimeters; UI converts between units (1 ft = 30.48 cm).
- Weight supported units: kg (kilograms), lb (pounds).
  - Internal storage is in kilograms; UI converts between units.

Usage notes
- Use the dropdown beside each input to pick units.
- Typing and sliders are synchronized; sliders operate on the internal model units (cm/kg), text displays the chosen unit.
- Save to History persists the converted model values (cm/kg).

Getting started (quick)
1. Open `pubspec.yaml` and add these dependencies:
   - sqflite: ^2.0.0
   - path: ^1.8.0

   Example:
   dependencies:
     flutter:
       sdk: flutter
     sqflite: ^2.0.0
     path: ^1.8.0

2. Run:
   flutter pub get

3. Run the app:
   flutter run

How it works (implementation notes)
- Database:
  - Implemented with sqflite in `lib/data/bmi_database.dart`.
  - Table `bmi_records` stores: id, bmi, category, height, weight, gender, createdAt (ISO string).
- Models:
  - `lib/model/BmiRecord.dart` maps records to/from DB rows.
  - `lib/model/BmiModel.dart` contains BMI calculation logic (unchanged).
- ViewModel:
  - `lib/viewmodel/BmiViewModel.dart` exposes BMI calculation, saveRecord() and history loading.
- UI:
  - Main screen: `lib/view/viewScreen.dart` — you can save the current BMI using "Save to History".
  - History screen: `lib/view/historyScreen.dart` — view saved entries and clear all.

Usage
- Adjust height and weight sliders.
- When a BMI is shown, tap "Save to History" to persist the record.
- Tap the history icon (top-right) to open the History screen.

Notes & improvements
- Currently saving is manual (via the Save button) to avoid too-frequent writes during slider movement.
- You can extend the DB with more fields (notes, goal, user id) or sync with remote storage.
- For large projects consider state management (Provider / Riverpod) and migrations for DB schema changes.

If you add more features, remember to run `flutter pub get` after editing dependencies.
