/// An exception reported by the native autocomplete or geocoding provider.
class NativeAddressAutocompleteException implements Exception {
  /// Creates a native autocomplete exception.
  const NativeAddressAutocompleteException(this.message, {this.code});

  /// Human-readable error message.
  final String message;

  /// Optional platform error code.
  final String? code;

  @override
  String toString() {
    if (code == null) {
      return message;
    }
    return '$code: $message';
  }
}
