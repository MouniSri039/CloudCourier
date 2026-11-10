# Cloud Courier – Mobile Application Development Activity 14

## 1. Test Environment

- Platform: Android
- Emulator: Android virtual device (Pixel-series emulator)
- Android version: Android 17 (API 37)
- Flutter: 3.47.2
- Dart: 3.13.2
- Firebase Core: 4.0.0
- Firebase Messaging: 16.0.0
- Notification permission: Authorized
- Firebase project: AutumnMarket
- Package name: `com.example.cloud_courier`

## 2. Notification Payloads Used

**Valid notification**

- Title: New promotion
- Body: Switch the screen to the promo asset
- `action`: `update_ui`
- `asset`: `promo`

**Invalid notification**

- Title: Invalid payload test
- Body: This message should be rejected
- `action`: `update_ui`
- `asset`: `unsupported`

## 3. Test Results

| Test | Expected behavior | Actual observation | Result | Evidence |
|---|---|---|---|---|
| T1 – Foreground | Receive message using `onMessage` and update the UI | Promo image and notification details displayed correctly | PASS | T1-foreground.png |
| T2 – Background | Open the app through a notification using `onMessageOpenedApp` | Notification appeared and tapping it opened the app with the updated content | PASS | T2-background-notification.png, T2-background-opened.png |
| T3 – Terminated | Open the app through a notification using `getInitialMessage` | App launched through the notification and displayed the promo content | PASS | T3-terminated.png |
| T4 – Invalid payload | Reject unsupported asset and preserve previous content | Unsupported asset was rejected, diagnostic appeared, and the app did not crash | PASS* | T4-invalid.png |

*T4 confirmed preservation of the content that was present when the invalid message arrived. Preservation of the earlier promo state across an application restart was not verified.*

## 4. Graduate Reflection

### Response 1 – Setup and payload handling

While developing Cloud Courier, I learned how Firebase Cloud Messaging connects a Flutter application with notifications sent from Firebase Console. I used a centralized service to handle incoming messages and validate their data before updating the screen. I chose this approach because it keeps the messaging logic organized instead of placing everything inside the UI. I also understood that an FCM token identifies an app installation, not a user's identity or permission to access protected information.

### Response 2 – Testing different app states

One of the most interesting parts was testing the application in foreground, background, and terminated states. I learned that each situation uses a different Firebase Messaging handler. I also understood that background processing and tapping a notification are different events because the background handler runs separately and cannot directly update Flutter widgets. I tested these situations using an Android emulator and recorded the results. Since I used only one emulator, I cannot assume the exact same behavior on every device.

### Response 3 – Validation and improvements

I also tested an invalid asset value to see how the application would respond. Instead of crashing, it displayed a diagnostic message and preserved the existing screen content. This helped me understand why validating incoming data is important. If I continue developing this application, I would add local storage so that the last successfully received promotion remains available even after restarting the application.

## 5. Design Decisions and Critical Analysis

### My initial design decision

I decided to keep Firebase messaging logic in a separate service instead of putting all the listeners directly inside the home screen. I wanted the application to have a clear separation between receiving messages and displaying their content.

### Possible lifecycle risk

One issue I considered was that notifications can arrive when the application is not open. A background handler and a notification-tap handler do not perform the same task. If these situations are handled incorrectly, the application might miss an update or try to change UI elements from a background isolate.

### Tests used to check the design

1. Send a valid notification while the application is open.
2. Send a notification while the application is in the background and tap it.
3. Send a notification after removing the application from recent apps and tap it to reopen the application.

I also tested an unsupported asset value to check whether the existing content would be preserved.

### Alternative approach

Another possible approach would be to put the Firebase listeners directly inside the home screen widget. This might be easier for a very small application, but it could make the code harder to maintain and increase the risk of duplicate listeners. I preferred a separate service because it keeps the messaging behavior in one place.

### What I would improve next

I would add local storage to remember the last valid notification. I would test this by receiving a promotion, closing and reopening the application, and checking whether the same title and image appear. I would then send an invalid payload and verify that the stored content remains unchanged.

## 6. Limitations

- Testing was performed on one Android emulator.
- Notification delivery depends on internet connectivity, device state, and Android operating-system policies.
- Background processing cannot directly update foreground widget state.
- FCM registration tokens identify installations and should not be treated as authentication credentials.
- The application currently uses local images rather than images downloaded from a server.

## 7. Development and Verification

During development, I used AI to understand errors, clear doubts, and learn concepts when I got stuck. I checked the suggestions against my code and tested the application myself.

Final verification:

- `flutter pub get` – Successful.
- `flutter analyze` – No issues found.
- `flutter test` – All 2 automated tests passed.
- Android debug build – Successful.
- Firebase Console notification tests – T1, T2, T3, and T4 performed.

