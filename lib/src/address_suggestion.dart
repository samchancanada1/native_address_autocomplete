/// A lightweight autocomplete result shown in the suggestions dropdown.
///
/// Suggestions are intended for display and selection. Call
/// `NativeAddressAutocomplete.resolve` when you need the best available
/// coordinate and normalized address components for the selected suggestion.
class AddressSuggestion {
  /// Creates an autocomplete suggestion.
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

  /// Stable provider id for this suggestion when the platform supplies one.
  final String id;

  /// Main line of text, usually the street address or place name.
  final String primaryText;

  /// Secondary line of text, usually city, region, or country context.
  final String? secondaryText;

  /// Full display text for the suggestion.
  final String fullText;

  /// Latitude when the platform returns coordinates with the suggestion.
  final double? latitude;

  /// Longitude when the platform returns coordinates with the suggestion.
  final double? longitude;

  /// ISO 3166 country code when available.
  final String? countryCode;

  /// Street number when available.
  final String? streetNumber;

  /// Street name when available.
  final String? street;

  /// City or locality when available.
  final String? city;

  /// State, province, or administrative area when available.
  final String? state;

  /// Postal or ZIP code when available.
  final String? postalCode;

  /// Country name when available.
  final String? country;

  /// Creates a suggestion from a platform channel map.
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

  /// Converts this suggestion into a platform channel map.
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
