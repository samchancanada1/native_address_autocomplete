/// A selected address resolved into coordinates and address components.
///
/// Platform geocoders do not always return every component. Treat nullable
/// fields as optional and prefer [fullText] for display.
class ResolvedAddress {
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

  final String? primaryText;
  final String? secondaryText;
  final String fullText;
  final String? streetNumber;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? countryCode;
  final double? latitude;
  final double? longitude;

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
