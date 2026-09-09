import 'address_result_type.dart';

/// Options passed to the native autocomplete provider.
class AddressAutocompleteOptions {
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

  final String query;
  final List<String> countries;
  final int limit;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;
  final Set<AddressResultType> resultTypes;
  final String? localeTag;
  final int? requestId;

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
