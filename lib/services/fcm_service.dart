
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models/message_update.dart';

/// Runs in a separate background isolate.
/// It must never update foreground Flutter widget state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint(
    'onBackgroundMessage: ${message.messageId}',
  );

  // Background processing only. UI updates happen through foreground
  // listeners or notification-open handlers.
}

class FCMService {
  FCMService._();

  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  StreamController<MessageUpdate> _updatesController =
      StreamController<MessageUpdate>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedSubscription;

  MessageUpdate _currentUpdate = MessageUpdate.initial();

  int _receiptCount = 0;
  bool _initialized = false;
  bool _disposed = false;

  Stream<MessageUpdate> get updates => _updatesController.stream;

  MessageUpdate get currentUpdate => _currentUpdate;

  int get receiptCount => _receiptCount;

  /// Returns the FCM installation token.
  /// This token is not a user identity or authorization credential.
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Requests notification permission.
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initializes listeners once and processes notification-triggered
  /// launches from the terminated state.
  Future<void> initialize() async {
    if (_initialized) return;

    // Recreate the stream if the service was previously disposed.
    if (_updatesController.isClosed) {
      _updatesController =
          StreamController<MessageUpdate>.broadcast();
    }

    _disposed = false;
    _initialized = true;

    _foregroundSubscription =
        FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        _processMessage(message, 'onMessage');
      },
      onError: (Object error) {
        _publishDiagnostic(
          'Foreground listener error: $error',
          'onMessage',
        );
      },
    );

    _openedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        _processMessage(message, 'onMessageOpenedApp');
      },
      onError: (Object error) {
        _publishDiagnostic(
          'Notification-open listener error: $error',
          'onMessageOpenedApp',
        );
      },
    );

    try {
      final RemoteMessage? initialMessage =
          await _messaging.getInitialMessage();

      if (initialMessage != null && !_disposed) {
        _processMessage(
          initialMessage,
          'getInitialMessage',
        );
      }
    } catch (error) {
      _publishDiagnostic(
        'Could not inspect initial message: $error',
        'getInitialMessage',
      );
    }
  }

  /// Validates custom data before changing visible application content.
  void _processMessage(
    RemoteMessage message,
    String handler,
  ) {
    if (_disposed) return;

    _receiptCount++;

    // Validate types rather than assuming all incoming values are strings.
    final Object? rawAction = message.data['action'];
    final Object? rawAsset = message.data['asset'];

    final String? action =
        rawAction is String ? rawAction : null;

    final String? requestedAsset =
        rawAsset is String ? rawAsset : null;

    final String messageId =
        message.messageId ?? 'Unavailable';

    if (action != 'update_ui') {
      _publishDiagnostic(
        'Rejected message: unsupported or missing action.',
        handler,
        messageId: messageId,
      );
      return;
    }

    if (requestedAsset == null || requestedAsset.isEmpty) {
      _publishDiagnostic(
        'Rejected message: missing or invalid asset key.',
        handler,
        messageId: messageId,
      );
      return;
    }

    if (requestedAsset != 'default' &&
        requestedAsset != 'promo') {
      _publishDiagnostic(
        'Rejected message: unsupported asset "$requestedAsset". '
        'Previous content was preserved.',
        handler,
        messageId: messageId,
      );
      return;
    }

    final String title =
        message.notification?.title ??
        'Cloud update received';

    final String body =
        message.notification?.body ??
        'A new update is available.';

    _currentUpdate = _currentUpdate.copyWith(
      title: title,
      body: body,
      asset: requestedAsset,
      handler: handler,
      messageId: messageId,
      diagnostic: 'Valid payload accepted.',
      receiptCount: _receiptCount,
    );

    _emit();
  }

  /// Updates diagnostics without changing the previous title, body,
  /// or image selection.
  void _publishDiagnostic(
    String diagnostic,
    String handler, {
    String messageId = 'Unavailable',
  }) {
    if (_disposed) return;

    _currentUpdate = _currentUpdate.copyWith(
      handler: handler,
      messageId: messageId,
      diagnostic: diagnostic,
      receiptCount: _receiptCount,
    );

    _emit();
  }

  void _emit() {
    if (!_disposed && !_updatesController.isClosed) {
      _updatesController.add(_currentUpdate);
    }
  }

  /// Cancels service-owned listeners and closes the stream.
  /// The service can be initialized again if required.
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    _initialized = false;

    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();

    _foregroundSubscription = null;
    _openedSubscription = null;

    await _updatesController.close();
  }
}
