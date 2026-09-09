import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_address_autocomplete/native_address_autocomplete.dart';
import 'package:native_address_autocomplete/native_address_autocomplete_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelNativeAddressAutocomplete platform =
      MethodChannelNativeAddressAutocomplete();
  const MethodChannel channel = MethodChannel('native_address_autocomplete');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isAvailable returns the native availability', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'isAvailable');
          return true;
        });

    expect(await platform.isAvailable(), isTrue);
  });

  test('suggestAddresses parses native suggestion maps', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'suggestAddresses');
          expect(methodCall.arguments, containsPair('query', '1600 Amph'));
          expect(methodCall.arguments, containsPair('limit', 5));
          expect(
            methodCall.arguments,
            containsPair('resultTypes', <String>['address', 'pointOfInterest']),
          );
          expect(methodCall.arguments, containsPair('locale', 'zh-Hant-TW'));
          expect(methodCall.arguments, containsPair('requestId', 7));

          return <Map<String, Object?>>[
            <String, Object?>{
              'id': '1',
              'primaryText': '1600 Amphitheatre Parkway',
              'secondaryText': 'Mountain View, CA',
              'fullText': '1600 Amphitheatre Parkway, Mountain View, CA',
              'latitude': 37.422,
              'longitude': -122.084,
              'countryCode': 'US',
              'street': 'Amphitheatre Parkway',
              'city': 'Mountain View',
              'state': 'CA',
              'postalCode': '94043',
              'country': 'United States',
            },
          ];
        });

    final List<AddressSuggestion> suggestions = await platform.suggestAddresses(
      const AddressAutocompleteOptions(
        query: '1600 Amph',
        localeTag: 'zh-Hant-TW',
        requestId: 7,
      ),
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.primaryText, '1600 Amphitheatre Parkway');
    expect(suggestions.single.countryCode, 'US');
    expect(suggestions.single.city, 'Mountain View');
  });

  test('resolveAddress parses native resolved address maps', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'resolveAddress');
          expect(methodCall.arguments, containsPair('locale', 'fr-CA'));
          expect(methodCall.arguments, containsPair('requestId', 8));
          expect(
            methodCall.arguments,
            containsPair(
              'fullText',
              '1600 Amphitheatre Parkway, Mountain View, CA',
            ),
          );

          return <String, Object?>{
            'primaryText': '1600 Amphitheatre Parkway',
            'secondaryText': 'Mountain View, CA 94043, United States',
            'fullText': '1600 Amphitheatre Parkway, Mountain View, CA 94043',
            'street': 'Amphitheatre Parkway',
            'city': 'Mountain View',
            'state': 'CA',
            'postalCode': '94043',
            'country': 'United States',
            'countryCode': 'US',
            'latitude': 37.422,
            'longitude': -122.084,
          };
        });

    final ResolvedAddress? resolved = await platform.resolveAddress(
      const AddressSuggestion(
        id: '1',
        primaryText: '1600 Amphitheatre Parkway',
        fullText: '1600 Amphitheatre Parkway, Mountain View, CA',
      ),
      localeTag: 'fr-CA',
      requestId: 8,
    );

    expect(resolved?.city, 'Mountain View');
    expect(resolved?.postalCode, '94043');
  });
}
