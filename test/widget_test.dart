
import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_courier/models/message_update.dart';

void main() {
  test('initial message state is correct', () {
    final update = MessageUpdate.initial();

    expect(update.title, 'Welcome to Cloud Courier');
    expect(update.asset, 'default');
    expect(update.receiptCount, 0);
    expect(update.handler, 'None yet');
  });

  test('copyWith preserves existing values when omitted', () {
    final initial = MessageUpdate.initial();

    final updated = initial.copyWith(
      handler: 'onMessage',
      diagnostic: 'Valid payload accepted.',
    );

    expect(updated.title, initial.title);
    expect(updated.asset, initial.asset);
    expect(updated.handler, 'onMessage');
    expect(updated.diagnostic, 'Valid payload accepted.');
  });
}
