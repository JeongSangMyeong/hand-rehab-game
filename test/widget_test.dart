import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_rehab_game/main.dart';

void main() {
  testWidgets('App shows the Bluetooth connection screen on launch',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('블루투스 연결하기'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
