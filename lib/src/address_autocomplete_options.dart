import 'address_result_type.dart';

/// Options passed to the native autocomplete provider.
class AddressAutocompleteOptions {
  /// Creates a native autocomplete request options object.
  const AddressAutocompleteOptions({
    required this.query,
    this.countries = const <String>[],
    this.limit = 5,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.resultTypes = const <AddressResultType>{
      AddressResultType.address,
      AddressResultType.pointOfInterest,
    },
    this.localeTag,
    this.requestId,
  });

  /// Search text entered by the user.
  final String query;

  /// ISO 3166 country codes used to prefer or filter results where supported.
  final List<String> countries;

  /// Maximum number of suggestions requested.
  final int limit;

  /// Latitude used as the center of the optional search bias.
  final double? latitude;

  /// Longitude used as the center of the optional search bias.
  final double? longitude;

  /// Radius, in meters, for the optional search bias.
  final double? radiusMeters;

  /// Requested result types.
  final Set<AddressResultType> resultTypes;

  /// BCP 47 language tag, such as `en-US` or `zh-Hant-TW`.
  final String? localeTag;

  /// Request id used to ignore stale native responses.
  final int? requestId;

  /// Converts these options into a platform channel map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'query': query,
      'countries': countries,
      'limit': limit,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'resultTypes': resultTypes
          .map((AddressResultType resultType) => resultType.name)
          .toList(growable: false),
      'locale': localeTag,
      'requestId': requestId,
    };
  }
}
