import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_courier/main.dart';

void main() {
  testWidgets('Cloud Courier app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const CloudCourierApp());

    expect(find.text('Cloud Courier'), findsOneWidget);
  });
}