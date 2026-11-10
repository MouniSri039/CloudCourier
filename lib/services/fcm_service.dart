
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/message_update.dart';

/// Must be top-level. Background handlers cannot update Flutter widget state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  debugPrint(
    'Background message received: ${message.messageId}',
  );

  // Do not call setState or access foreground widgets here.
  // The operating system may display the notification.
}

class FCMService {
  FCMService._();

  static final FCMService instance = FCMService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final StreamController<MessageUpdate> _updatesController =
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

  /// Current installation token. It is not a user identity or permission.
  Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Requests notification permission and returns the authorization status.
  Future<NotificationSettings> requestPermission() {
    return _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Initializes listeners once and handles notification-triggered cold starts.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;

    _initialized = true;

    _foregroundSubscription = FirebaseMessaging.onMessage.listen(
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

      if (initialMessage != null) {
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

  /// Validates the payload before changing visible content.
  void _processMessage(
    RemoteMessage message,
    String handler,
  ) {
    if (_disposed) return;

    _receiptCount++;

    final String? action = message.data['action'] as String?;
    final String? requestedAsset = message.data['asset'] as String?;

    final String messageId = message.messageId ?? 'Unavailable';

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
        'Rejected message: missing asset key.',
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
        message.notification?.title ?? 'Cloud update received';

    final String body =
        message.notification?.body ?? 'A new update is available.';

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

  void _publishDiagnostic(
    String diagnostic,
    String handler, {
    String messageId = 'Unavailable',
  }) {
    if (_disposed) return;

    // Preserve the previous title and image on invalid payloads.
    _currentUpdate = _currentUpdate.copyWith(
      handler: handler,
      messageId: messageId,
      diagnostic: diagnostic,
      receiptCount: _receiptCount,
    );

    _emit();
  }

  void _emit() {
    if (!_updatesController.isClosed) {
      _updatesController.add(_currentUpdate);
    }
  }

  /// Cancels listeners and releases the stream controller.
  Future<void> dispose() async {
    if (_disposed) return;

    _disposed = true;
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _updatesController.close();

    _initialized = false;
  }
}
