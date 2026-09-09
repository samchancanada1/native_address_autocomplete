/// An exception reported by the native autocomplete or geocoding provider.
class NativeAddressAutocompleteException implements Exception {
  const NativeAddressAutocompleteException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() {
    if (code == null) {
      return message;
    }
    return '$code: $message';
  }
}
