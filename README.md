# Cloud Courier – Firebase Cloud Messaging in Flutter

## Overview
Cloud Courier is a Flutter application demonstrating Firebase Cloud Messaging (FCM) across foreground, background, and terminated application states.

The application processes notification data to dynamically update its displayed title, message, and image. It also validates incoming payloads and preserves existing content when invalid data is received.

## Technology Stack
- Flutter 3.47.2
- Dart 3.13.2
- Firebase Core 4.0.0
- Firebase Messaging 16.0.0
- Firebase Cloud Messaging
- Android Emulator (Android 17, API 37)

## Features
- FCM initialization and device registration.
- Notification permission handling and FCM token retrieval.
- Foreground message handling using `FirebaseMessaging.onMessage`.
- Background notification interaction using `FirebaseMessaging.onMessageOpenedApp`.
- Terminated-state notification handling using `getInitialMessage()`.
- Top-level background message handler.
- Custom data processing using `action` and `asset`.
- Payload validation and diagnostic reporting.
- Dynamic local image updates.
- Invalid payload rejection without application crashes.
- Previous UI content preservation.

## Project Structure
```text
lib/
  main.dart
  firebase_options.dart
  models/
    message_update.dart
  services/
    fcm_service.dart

assets/
  images/
    default.jpg
    promo.png

evidence/
  T1-foreground.png
  T2-background-notification.png
  T2-background-opened.png
  T3-terminated.png
  T4-invalid.png
```

## Setup Instructions

1. Install Flutter and Android Studio.
2. Clone this repository.
3. Open the project directory.
4. Install dependencies:

```bash
flutter pub get
```

5. Configure Firebase for Android:

```bash
flutterfire configure --project=autumnmarket --platforms=android
```

6. Run the application:

```bash
flutter run
```

## Test Payload

Valid notification:

- Title: New promotion
- Body: Switch the screen to the promo asset

Custom data:

```text
action = update_ui
asset = promo
```

Invalid payload test:

```text
action = update_ui
asset = unsupported
```

## Test Scenarios

| Test | Scenario | Expected Handler |
|---|---|---|
| T1 | Foreground notification | onMessage |
| T2 | Background notification tap | onMessageOpenedApp |
| T3 | Terminated notification tap | getInitialMessage |
| T4 | Invalid foreground payload | onMessage with rejection diagnostic |

See the `evidence/` directory for test screenshots.

## Security and Limitations
- FCM registration tokens identify app installations, not authenticated users.
- Tokens must not be committed to the repository or shared publicly.
- No passwords or server credentials are included in notification payloads.
- Message delivery depends on network connectivity, device state, and Android notification policies.
- Background message processing cannot directly update Flutter widget state.

## Author
Mouni Sri Nallapaneni
003013851

Mobile Application Development – Activity 14
