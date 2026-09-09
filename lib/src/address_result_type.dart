/// The kind of result returned by iOS MapKit autocomplete.
///
/// Android `Geocoder` does not expose the same result-type filtering, so this
/// setting is currently applied on iOS only.
enum AddressResultType {
  /// Street addresses and address-like locations.
  address,

  /// Named places, businesses, landmarks, and other points of interest.
  pointOfInterest,
}
