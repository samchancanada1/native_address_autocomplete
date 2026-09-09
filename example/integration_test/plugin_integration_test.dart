// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:native_address_autocomplete/native_address_autocomplete.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty query returns no suggestions', (
    WidgetTester tester,
  ) async {
    const NativeAddressAutocomplete plugin = NativeAddressAutocomplete();
    final List<AddressSuggestion> suggestions = await plugin.suggest('');

    expect(suggestions, isEmpty);
  });
}
