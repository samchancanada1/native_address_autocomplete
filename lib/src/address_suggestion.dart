/// A lightweight autocomplete result shown in the suggestions dropdown.
///
/// Suggestions are intended for display and selection. Call
/// `NativeAddressAutocomplete.resolve` when you need the best available
/// coordinate and normalized address components for the selected suggestion.
class AddressSuggestion {
  const AddressSuggestion({
    required this.id,
    required this.primaryText,
    required this.fullText,
    this.secondaryText,
    this.latitude,
    this.longitude,
    this.countryCode,
    this.streetNumber,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  final String id;
  final String primaryText;
  final String? secondaryText;
  final String fullText;
  final double? latitude;
  final double? longitude;
  final String? countryCode;
  final String? streetNumber;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  factory AddressSuggestion.fromMap(Map<Object?, Object?> map) {
    return AddressSuggestion(
      id: map['id'] as String? ?? '',
      primaryText: map['primaryText'] as String? ?? '',
      secondaryText: map['secondaryText'] as String?,
      fullText: map['fullText'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      countryCode: map['countryCode'] as String?,
      streetNumber: map['streetNumber'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postalCode'] as String?,
      country: map['country'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'primaryText': primaryText,
      'secondaryText': secondaryText,
      'fullText': fullText,
      'latitude': latitude,
      'longitude': longitude,
      'countryCode': countryCode,
      'streetNumber': streetNumber,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
    };
  }

  @override
  String toString() => fullText;
}
