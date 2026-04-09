# Longevity Compass Flutter App

Flutter foundation for the patient-facing Longevity Compass across:

- iOS
- Android
- web

## Current Scope

The first build slice includes:

1. Home Compass
2. Weekly Plan
3. Coach Chat
4. Offers
5. Profile And Progress

All of these surfaces are derived from the Compass API.

## Project State

This directory now contains both:

- the hand-written Longevity Compass app code
- the generated Flutter project shell for `ios/`, `android/`, and `web/`

## Local Run

Start the API from the repo root:

```bash
./scripts/run_api.sh
```

Optional: save your local defaults once:

```bash
cp .env.example .env.local
```

Configure Firebase when you are ready to connect the app to a real Firebase project:

```bash
./scripts/setup_firebase.sh --project your-firebase-project-id
```

Publish the current local warehouse into Firestore so the app can read patient
data from Firebase:

```bash
./scripts/sync_firestore.sh --project your-firebase-project-id
```

Then use the scripted launchers from the repo root:

```bash
./scripts/run_ios.sh
./scripts/run_android.sh
./scripts/run_web.sh
```

Useful options:

```bash
./scripts/run_android.sh --emulator
./scripts/run_android.sh --physical --device-id RFCW90RPXXV
./scripts/run_android.sh --firebase-project your-firebase-project-id
./scripts/run_ios.sh --firebase-project your-firebase-project-id
./scripts/run_web.sh --firebase-project your-firebase-project-id
```

Both run scripts:

- run `flutter pub get`
- enable Firebase automatically if the app is already configured
- can configure Firebase first when `--firebase-project` is provided
- auto-configure Firebase on first launch when `.env.local` already contains `FIREBASE_PROJECT_ID`
- auto-load `.env.local` for your Firebase project and local runtime defaults
- warn if the backend API is not running at the expected local address

With Firebase enabled, the app reads its main data from Firestore:

- `patient_summaries`
- `patient_experiences`

Coach message persistence stays in:

- `coach_conversations/{patientId}/messages`

## Current Environment

The local machine is now set up with:

- Flutter SDK
- Android Studio
- Android SDK and build tools
- Android emulator tooling
- Firebase CLI
- FlutterFire CLI
- Google Cloud CLI

A default Android AVD named `Pixel_8_API_36` is already created.

## Runtime Flags

- `APP_API_BASE_URL`
- `APP_DEMO_PATIENT_ID`
- `APP_ENABLE_FIREBASE`
