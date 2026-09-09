/// A selected address resolved into coordinates and address components.
///
/// Platform geocoders do not always return every component. Treat nullable
/// fields as optional and prefer [fullText] for display.
class ResolvedAddress {
  /// Creates a resolved address.
  const ResolvedAddress({
    required this.fullText,
    this.primaryText,
    this.secondaryText,
    this.streetNumber,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.countryCode,
    this.latitude,
    this.longitude,
  });

  /// Main display line, usually the street address or place name.
  final String? primaryText;

  /// Secondary display line, usually city, region, or country context.
  final String? secondaryText;

  /// Full formatted address text.
  final String fullText;

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

  /// ISO 3166 country code when available.
  final String? countryCode;

  /// Latitude when available.
  final double? latitude;

  /// Longitude when available.
  final double? longitude;

  /// Creates a resolved address from a platform channel map.
  factory ResolvedAddress.fromMap(Map<Object?, Object?> map) {
    return ResolvedAddress(
      primaryText: map['primaryText'] as String?,
      secondaryText: map['secondaryText'] as String?,
      fullText: map['fullText'] as String? ?? '',
      streetNumber: map['streetNumber'] as String?,
      street: map['street'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      postalCode: map['postalCode'] as String?,
      country: map['country'] as String?,
      countryCode: map['countryCode'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  /// Converts this resolved address into a platform channel map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'primaryText': primaryText,
      'secondaryText': secondaryText,
      'fullText': fullText,
      'streetNumber': streetNumber,
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
