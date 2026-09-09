import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_address_autocomplete/native_address_autocomplete.dart';

class SlowAutocomplete extends NativeAddressAutocomplete {
  const SlowAutocomplete();

  @override
  Future<List<AddressSuggestion>> suggest(
    String query, {
    List<String> countries = const <String>[],
    int limit = 5,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    Set<AddressResultType> resultTypes = const <AddressResultType>{
      AddressResultType.address,
      AddressResultType.pointOfInterest,
    },
    Locale? locale,
    String? localeTag,
    int? requestId,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const <AddressSuggestion>[];
  }
}

class ImmediateAutocomplete extends NativeAddressAutocomplete {
  const ImmediateAutocomplete();

  @override
  Future<List<AddressSuggestion>> suggest(
    String query, {
    List<String> countries = const <String>[],
    int limit = 5,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    Set<AddressResultType> resultTypes = const <AddressResultType>{
      AddressResultType.address,
      AddressResultType.pointOfInterest,
    },
    Locale? locale,
    String? localeTag,
    int? requestId,
  }) async {
    return const <AddressSuggestion>[
      AddressSuggestion(
        id: '1',
        primaryText: '100 Queen St W',
        secondaryText: 'Toronto, ON',
        fullText: '100 Queen St W, Toronto, ON',
      ),
      AddressSuggestion(
        id: '2',
        primaryText: '101 Queen St W',
        secondaryText: 'Toronto, ON',
        fullText: '101 Queen St W, Toronto, ON',
      ),
    ];
  }

  @override
  Future<ResolvedAddress?> resolve(
    AddressSuggestion suggestion, {
    Locale? locale,
    String? localeTag,
    int? requestId,
  }) async {
    return ResolvedAddress(
      primaryText: suggestion.primaryText,
      fullText: suggestion.fullText,
      street: 'Queen St W',
      city: 'Toronto',
      state: 'ON',
      countryCode: 'CA',
      latitude: 43.6532,
      longitude: -79.3832,
    );
  }
}

class FailingAutocomplete extends NativeAddressAutocomplete {
  const FailingAutocomplete();

  @override
  Future<List<AddressSuggestion>> suggest(
    String query, {
    List<String> countries = const <String>[],
    int limit = 5,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    Set<AddressResultType> resultTypes = const <AddressResultType>{
      AddressResultType.address,
      AddressResultType.pointOfInterest,
    },
    Locale? locale,
    String? localeTag,
    int? requestId,
  }) async {
    throw Exception('No service');
  }
}

void main() {
  testWidgets('shows a trailing loading indicator while searching', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NativeAddressAutocompleteTextField(
            provider: SlowAutocomplete(),
            minChars: 3,
            loadingIndicatorBuilder: _buildLoadingIndicator,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '1600');
    await tester.pump();

    expect(find.byKey(_loadingIndicatorKey), findsOneWidget);
  });

  testWidgets('clear button clears the text field', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NativeAddressAutocompleteTextField(
            provider: ImmediateAutocomplete(),
            minChars: 1,
            showClearButton: true,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Queen');
    await tester.pump();

    expect(find.byTooltip('Clear'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    final TextField textField = tester.widget(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
  });

  testWidgets('shows an error builder when suggestions fail', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeAddressAutocompleteTextField(
            provider: const FailingAutocomplete(),
            minChars: 1,
            debounce: Duration.zero,
            errorBuilder: (BuildContext context, Object error) {
              return const Text('Custom error');
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Queen');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Custom error'), findsOneWidget);
  });

  testWidgets('enter selects the highlighted suggestion', (
    WidgetTester tester,
  ) async {
    AddressSuggestion? selectedSuggestion;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeAddressAutocompleteTextField(
            provider: const ImmediateAutocomplete(),
            minChars: 1,
            debounce: Duration.zero,
            onSelected: (AddressSuggestion suggestion) {
              selectedSuggestion = suggestion;
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Queen');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(selectedSuggestion?.fullText, '100 Queen St W, Toronto, ON');
  });

  testWidgets('address controller tracks suggestions and resolved address', (
    WidgetTester tester,
  ) async {
    final AddressAutocompleteController controller =
        AddressAutocompleteController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NativeAddressAutocompleteTextField(
            addressController: controller,
            provider: const ImmediateAutocomplete(),
            minChars: 1,
            debounce: Duration.zero,
            resolveOnSelected: true,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'Queen');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(controller.suggestions, hasLength(2));

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(controller.selectedSuggestion?.primaryText, '100 Queen St W');
    expect(controller.resolvedAddress?.city, 'Toronto');

    controller.dispose();
  });

  testWidgets('form field validates and stores a resolved address', (
    WidgetTester tester,
  ) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    ResolvedAddress? savedAddress;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: NativeAddressAutocompleteFormField(
              provider: const ImmediateAutocomplete(),
              minChars: 1,
              debounce: Duration.zero,
              validator: (ResolvedAddress? address) {
                return address == null ? 'Required' : null;
              },
              onSaved: (ResolvedAddress? address) {
                savedAddress = address;
              },
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Queen');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(formKey.currentState!.validate(), isTrue);
    formKey.currentState!.save();
    expect(savedAddress?.city, 'Toronto');
  });
}

const Key _loadingIndicatorKey = Key('trailing-loading-indicator');

Widget _buildLoadingIndicator(BuildContext context) {
  return const _LoadingIndicator();
}

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      key: _loadingIndicatorKey,
      width: 48,
      child: Center(
        child: SizedBox.square(
          dimension: 18,
          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
        ),
      ),
    );
  }
}
