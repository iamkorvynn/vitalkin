# VitalKin

A family health log for Android. Add the people you care for and keep their
blood pressure, blood sugar and weight readings in one place — with trends,
medicine reminders, and a doctor-ready PDF report.

> **VitalKin is a personal health log, not a medical device.** Readings are
> entered by you and are not a diagnosis. Always check important values with
> a clinician.

## Features

- **Family members** — add people with name, age, relation and optional
  height (used for BMI context).
- **Readings** — log blood pressure (systolic/diastolic), blood sugar
  (fasting or post-meal, mg/dL) and weight (kg), each with a date/time and an
  optional note. Readings are flagged Normal / Elevated / Borderline / High
  against standard healthy ranges.
- **Charts** — per member, per metric line charts of the last 14 readings
  (fl_chart), with dashed healthy-range reference lines (BP 120/80, fasting
  sugar 70–100, post-meal under 140).
- **Medicine reminders** — add medicines with a dose and up to 4 daily times.
  Daily local notifications are scheduled in the device timezone
  (flutter_local_notifications + timezone); permission is requested at
  runtime and the POST_NOTIFICATIONS permission is declared for Android 13+.
- **PDF report for the doctor** — generates a PDF with member details, the
  last 30 readings and the medicines list, then shares it via the system
  share sheet.
- **Share with family** — export a member's readings as CSV and share the
  file. Local file sharing only — no cloud, no account.
- **Private by design** — everything is stored locally in SQLite on the
  device. The app starts empty: no sample patients, no fake readings.
  First-run onboarding explains the app before any data is entered.

## Build & run

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Requires Flutter 3.50+ and Android SDK 36 (per this project's toolchain).
The release APK is built by the release pipeline; no secrets or API keys
are needed — the app has no backend.

## Tech

- Flutter + Material 3 (teal seed theme)
- sqflite — local storage (members, readings, medicines, meta)
- fl_chart — reading trend charts with healthy-range reference lines
- flutter_local_notifications + timezone — daily medicine reminders
- pdf + path_provider — doctor PDF report
- csv + share_plus — CSV export and sharing

## License

MIT — see [LICENSE](LICENSE).
