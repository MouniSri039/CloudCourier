
class MessageUpdate {
  final String title;
  final String body;
  final String asset;
  final String handler;
  final String messageId;
  final String diagnostic;
  final int receiptCount;

  const MessageUpdate({
    required this.title,
    required this.body,
    required this.asset,
    required this.handler,
    required this.messageId,
    required this.diagnostic,
    required this.receiptCount,
  });

  MessageUpdate copyWith({
    String? title,
    String? body,
    String? asset,
    String? handler,
    String? messageId,
    String? diagnostic,
    int? receiptCount,
  }) {
    return MessageUpdate(
      title: title ?? this.title,
      body: body ?? this.body,
      asset: asset ?? this.asset,
      handler: handler ?? this.handler,
      messageId: messageId ?? this.messageId,
      diagnostic: diagnostic ?? this.diagnostic,
      receiptCount: receiptCount ?? this.receiptCount,
    );
  }

  factory MessageUpdate.initial() {
    return const MessageUpdate(
      title: 'Welcome to Cloud Courier',
      body: 'Waiting for your first cloud message.',
      asset: 'default',
      handler: 'None yet',
      messageId: '—',
      diagnostic: 'Ready to receive messages.',
      receiptCount: 0,
    );
  }
}
