import 'dart:ui';

import '../native_address_autocomplete_platform_interface.dart';
import 'address_autocomplete_options.dart';
import 'address_locale.dart';
import 'address_result_type.dart';
import 'address_suggestion.dart';
import 'resolved_address.dart';

/// Client for native address autocomplete and address resolution.
///
/// The default implementation uses Apple MapKit on iOS and Android `Geocoder`
/// on Android. No Google API key is required.
class NativeAddressAutocomplete {
  const NativeAddressAutocomplete();

  /// Returns whether the native provider is available on the current platform.
  ///
  /// iOS returns true. Android delegates to `Geocoder.isPresent()`.
  Future<bool> isAvailable() {
    return NativeAddressAutocompletePlatform.instance.isAvailable();
  }

  /// Returns address suggestions for [query].
  ///
  /// [countries] accepts ISO 3166 country codes such as `US` or `CA`.
  /// [limit] caps the returned suggestions. [latitude], [longitude], and
  /// [radiusMeters] provide an optional location bias where supported.
  /// [resultTypes] filters MapKit results on iOS and is best-effort on Android.
  ///
  /// If [locale] or [localeTag] is omitted, the native platform uses the system
  /// or app locale. Android applies the requested locale to `Geocoder`; iOS
  /// MapKit follows the user's system/app language.
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
  }) {
    return NativeAddressAutocompletePlatform.instance.suggestAddresses(
      AddressAutocompleteOptions(
        query: query,
        countries: countries,
        limit: limit,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        resultTypes: resultTypes,
        localeTag: localeTag ?? localeToLanguageTag(locale),
        requestId: requestId,
      ),
    );
  }

  /// Resolves a selected [suggestion] into coordinates and address components.
  ///
  /// Returns null when the platform cannot resolve the selected suggestion.
  /// Returned components vary by platform and by provider data quality.
  Future<ResolvedAddress?> resolve(
    AddressSuggestion suggestion, {
    Locale? locale,
    String? localeTag,
    int? requestId,
  }) {
    return NativeAddressAutocompletePlatform.instance.resolveAddress(
      suggestion,
      localeTag: localeTag ?? localeToLanguageTag(locale),
      requestId: requestId,
    );
  }
}
