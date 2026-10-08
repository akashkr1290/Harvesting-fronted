// Smoke tests: the app builds, the first-launch language screen appears,
// and Simple-mode helpers behave.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:harvest_flow/l10n/simple_strings.dart';
import 'package:harvest_flow/main.dart';
import 'package:harvest_flow/services/voice_service.dart';
import 'package:harvest_flow/widgets/simple/simple_ui.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('App launches and asks for the language first', (WidgetTester tester) async {
    await tester.pumpWidget(const HarvestFlowApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(find.text('मराठी'), findsOneWidget);
  });

  testWidgets('Choosing a language shows the login screen in that language', (WidgetTester tester) async {
    await tester.pumpWidget(const HarvestFlowApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();
    expect(find.text('मोबाइल नंबर'), findsWidgets);
  });

  test('Every Simple-mode text exists in all 9 languages', () {
    final keys = simpleStrings['en']!.keys.toSet();
    for (final lang in ['hi', 'mr', 'te', 'ta', 'gu', 'kn', 'bn', 'as']) {
      expect(simpleStrings[lang]!.keys.toSet(), keys, reason: lang);
    }
  });

  test('Spoken numbers are understood, including Devanagari digits', () {
    expect(VoiceService.numberFrom('500 kilo'), 500);
    expect(VoiceService.numberFrom('५००'), 500);
    expect(VoiceService.numberFrom('৩২ টাকা'), 32);
    expect(VoiceService.numberFrom('nothing'), isNull);
  });

  test('Rupees use Indian grouping', () {
    expect(rupees(16000), '₹16,000');
    expect(rupees(1234567), '₹12,34,567');
    expect(rupees(999), '₹999');
  });
}
