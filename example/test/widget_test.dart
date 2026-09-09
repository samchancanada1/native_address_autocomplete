// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:native_address_autocomplete_example/main.dart';

void main() {
  testWidgets('shows the address autocomplete field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Native address autocomplete'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('City'), findsOneWidget);
    expect(find.text('State / Province'), findsOneWidget);
    expect(find.text('Postal code'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('Full text example'), findsOneWidget);
    expect(find.text('Full address'), findsOneWidget);
    expect(find.text('Styled results example'), findsOneWidget);
    expect(find.text('Styled address'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Custom loading example'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Custom loading example'), findsOneWidget);
    expect(find.text('Loading style address'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Results shown: 5'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Results shown: 5'), findsOneWidget);
  });
}
