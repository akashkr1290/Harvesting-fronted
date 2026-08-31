// Smoke test — just verifies the app widget tree builds without error.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:harvest_flow/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const HarvestFlowApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
