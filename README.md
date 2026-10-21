# SecuChat

SecuChat is a privacy-focused Flutter chat application. The repository contains
the mobile/desktop application and a local `chat` package that holds the
reusable messaging, encryption, Firebase, and service-layer code.

- [Google Play release](https://play.google.com/store/apps/details?id=com.developerik.secuchat)
- [Latest GitHub release](https://github.com/ishu17077/SecuChat/releases/latest)

## Features

- Email/password and Google authentication through Firebase
- One-to-one chat with encrypted local message storage
- Firebase Firestore and Realtime Database integration
- Typing indicators, message receipts, push notifications, and local
  notifications
- Image and file attachments
- Local SQLite persistence and encrypted shared preferences
- Android, iOS, macOS, Linux, Windows, and web Flutter targets

## Requirements

- Flutter **3.35.4** on the stable channel (the CI workflow uses this version)
- Dart 3.9 or newer, as provided by the matching Flutter SDK
- Android Studio and an Android SDK for Android development
- Xcode for iOS or macOS development
- A Firebase project configured for the platform you want to run

Check the local toolchain before starting:

```bash
flutter --version
flutter doctor
```

If you are unable to run flutter or flutter doctor raises errors refer to the [guide](https://docs.flutter.dev/install)

## Clone and install

```bash
git clone https://github.com/ishu17077/SecuChat.git
cd SecuChat
flutter pub get
```

The root application depends on the local `chat` package through
`chat/pubspec.yaml`. Installing dependencies from the repository root resolves
that package automatically.

## Configuration

### Runtime environment: `env.json`

The application reads `API_URL` from a Dart compile-time environment variable
in `lib/composition_root.dart`. The repository includes an example file:

```json
{
  "API_URL":https://yourapi-sever.com"
}
```

Create a local `env.json` from the example and change the URL if you are
running a different backend:

On Windows:

```bash
copy env.json.example env.json
```

On macOS/Linux:

```bash
cp env.json.example env.json
```

`env*.json` files are ignored by Git. Do not commit credentials, private
tokens, or other secrets to them. Flutter does not automatically load this
file; always pass it explicitly:

```bash
flutter run --dart-define-from-file=env.json
```

The app has a built-in default for `API_URL`, so it can start without the file,
but using the file is recommended for local development and builds.

### Firebase

Firebase is initialized during application startup and is required for
authentication, Firestore, Realtime Database, and messaging.

1. Create or select a Firebase project.
2. Register the application using the package/application identifier used by
   the target platform.
3. Enable the services used by the app:
   - Authentication providers required by your environment
   - Cloud Firestore
   - Realtime Database
   - Cloud Messaging
4. Add the platform configuration files:
   - Android: `android/app/google-services.json`
   - iOS: the Firebase `GoogleService-Info.plist` in the iOS Runner target
   - Other platforms: follow the Firebase setup for that Flutter target

Firebase configuration files are intentionally ignored by Git. Each developer
must supply their own project configuration.

For Android local development, generate the signing fingerprints from the
repository root:

```powershell
cd android
.\gradlew.bat signingReport
cd ..
```

On macOS/Linux:

```bash
cd android
chmod +x ./gradlew
./gradlew signingReport
cd ..
```

Add the debug SHA-1/SHA-256 fingerprints shown by `signingReport` to the
Android app registered in Firebase. Install Android Studio's SDK and
ADB/device drivers, then use an emulator or a USB-debugging-enabled device.

## Running the app

From the repository root:

```bash
flutter run --dart-define-from-file=env.json
```

To select a specific device:

```bash
flutter devices
flutter run -d <device-id> --dart-define-from-file=env.json
```

Useful release commands:

```bash
flutter build apk --dart-define-from-file=env.json
flutter build appbundle --dart-define-from-file=env.json
flutter build web --dart-define-from-file=env.json
```

When using VS Code, select a device from the status bar and run the Flutter
launch configuration. If the launch configuration does not include the
environment file, add `--dart-define-from-file=env.json` to its `args`.

## Tests and code quality

Run the root application tests and static analysis:

```bash
flutter test
flutter analyze
```

The `chat` package has its own dependency graph and test suite:

```bash
cd chat
flutter pub get
flutter pub run webcrypto:setup
flutter test
cd ..
```

The webcrypto setup is required by the package's encryption-related tests and
should be run after a fresh checkout or when its generated support files are
missing.

## Project structure

```text
SecuChat/
├── android/                 Android host, Gradle, manifests, and Firebase wiring
├── ios/                     iOS host project
├── linux/                   Linux Flutter runner
├── macos/                   macOS host project
├── web/                     Web runner and manifest
├── windows/                 Windows Flutter runner
├── assets/                  Application assets
├── lib/
│   ├── main.dart            Flutter entry point and MaterialApp routes
│   ├── composition_root.dart
│   │                         Dependency construction and application startup
│   ├── data/                SQLite data sources and database factories
│   ├── cache/               Local encrypted cache
│   ├── models/              Application data models
│   ├── notifications/       Firebase and local notification services
│   ├── state_management/    BLoC/Cubit state and event handling
│   ├── viewmodels/          Authentication, chat, and encryption view models
│   └── ui/                  Pages, routing, and reusable widgets
├── chat/
│   ├── lib/src/models/      Shared chat domain models
│   ├── lib/src/services/    Message, user, receipt, typing, and encryption services
│   └── test/                Reusable chat package tests
├── test/                    Root application tests and test utilities
├── env.json.example         Safe template for compile-time environment values
├── pubspec.yaml             Root Flutter application dependencies
└── analysis_options.yaml    Dart analyzer and lint configuration
```

### Application flow

1. `lib/main.dart` initializes Flutter and calls `CompositionRoot.configure()`.
2. `lib/composition_root.dart` initializes Firebase, the local database,
   encrypted storage, services, and BLoC/Cubit view models.
3. Authentication and onboarding route the user into the home screen.
4. UI pages dispatch events to state management and view models.
5. The `chat` package provides reusable domain services for messages, users,
   receipts, typing notifications, attachments, and encryption.

## Development notes

- Keep environment and Firebase configuration local; do not commit
  `env.json` or platform Firebase files.
- Keep reusable chat-domain logic in `chat/` and app-specific composition and
  presentation logic in the root `lib/` directory.
- Run both test suites when changing the shared `chat` package.
- Use `flutter clean` followed by `flutter pub get` if generated Flutter or
  platform artifacts become stale.

## Contributing

Bug reports, focused improvements, and pull requests are welcome. Please
describe the platform, Flutter version, reproduction steps, and any relevant
Firebase or backend configuration without including secrets.
