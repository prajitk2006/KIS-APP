import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kis/main.dart';

void main() {
  testWidgets('App starts on setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KisApp());

    expect(find.text('KIS'), findsWidgets);
    expect(find.text('Send files. Keep them yours.'), findsOneWidget);
    expect(find.text('Complete Setup'), findsOneWidget);
  });
}
