import 'package:flutter_test/flutter_test.dart';
import 'package:native_address_autocomplete/native_address_autocomplete.dart';
import 'package:native_address_autocomplete/native_address_autocomplete_method_channel.dart';
import 'package:native_address_autocomplete/native_address_autocomplete_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeAddressAutocompletePlatform
    with MockPlatformInterfaceMixin
    implements NativeAddressAutocompletePlatform {
  AddressAutocompleteOptions? lastOptions;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<AddressSuggestion>> suggestAddresses(
    AddressAutocompleteOptions options,
  ) async {
    lastOptions = options;
    return <AddressSuggestion>[
      AddressSuggestion(
        id: options.query,
        primaryText: options.query,
        fullText: '${options.query}, Toronto, ON',
        countryCode: 'CA',
      ),
    ];
  }

  @override
  Future<ResolvedAddress?> resolveAddress(
    AddressSuggestion suggestion, {
    String? localeTag,
    int? requestId,
  }) async {
    return ResolvedAddress(
      fullText: suggestion.fullText,
      city: 'Toronto',
      countryCode: 'CA',
      latitude: 43.6532,
      longitude: -79.3832,
    );
  }
}

void main() {
  final NativeAddressAutocompletePlatform initialPlatform =
      NativeAddressAutocompletePlatform.instance;

  test('$MethodChannelNativeAddressAutocomplete is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelNativeAddressAutocomplete>(),
    );
  });

  test('isAvailable forwards to the platform implementation', () async {
    const NativeAddressAutocomplete autocomplete = NativeAddressAutocomplete();
    final MockNativeAddressAutocompletePlatform fakePlatform =
        MockNativeAddressAutocompletePlatform();
    NativeAddressAutocompletePlatform.instance = fakePlatform;

    expect(await autocomplete.isAvailable(), isTrue);
  });

  test('suggest forwards options to the platform implementation', () async {
    const NativeAddressAutocomplete autocomplete = NativeAddressAutocomplete();
    final MockNativeAddressAutocompletePlatform fakePlatform =
        MockNativeAddressAutocompletePlatform();
    NativeAddressAutocompletePlatform.instance = fakePlatform;

    final List<AddressSuggestion> suggestions = await autocomplete.suggest(
      '1600 Amph',
      countries: const <String>['CA'],
      limit: 3,
      resultTypes: const <AddressResultType>{AddressResultType.address},
    );

    expect(suggestions, hasLength(1));
    expect(suggestions.single.fullText, '1600 Amph, Toronto, ON');
    expect(fakePlatform.lastOptions?.resultTypes, <AddressResultType>{
      AddressResultType.address,
    });
  });

  test(
    'resolve forwards a suggestion to the platform implementation',
    () async {
      const NativeAddressAutocomplete autocomplete =
          NativeAddressAutocomplete();
      final MockNativeAddressAutocompletePlatform fakePlatform =
          MockNativeAddressAutocompletePlatform();
      NativeAddressAutocompletePlatform.instance = fakePlatform;

      final ResolvedAddress? resolved = await autocomplete.resolve(
        const AddressSuggestion(
          id: '1',
          primaryText: '100 Queen St W',
          fullText: '100 Queen St W, Toronto, ON',
        ),
      );

      expect(resolved?.city, 'Toronto');
      expect(resolved?.latitude, 43.6532);
    },
  );
}
