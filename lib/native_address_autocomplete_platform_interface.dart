import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_address_autocomplete_method_channel.dart';
import 'src/address_autocomplete_options.dart';
import 'src/address_suggestion.dart';
import 'src/resolved_address.dart';

abstract class NativeAddressAutocompletePlatform extends PlatformInterface {
  /// Constructs a NativeAddressAutocompletePlatform.
  NativeAddressAutocompletePlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeAddressAutocompletePlatform _instance =
      MethodChannelNativeAddressAutocomplete();

  /// The default instance of [NativeAddressAutocompletePlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeAddressAutocomplete].
  static NativeAddressAutocompletePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeAddressAutocompletePlatform] when
  /// they register themselves.
  static set instance(NativeAddressAutocompletePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isAvailable() {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  Future<List<AddressSuggestion>> suggestAddresses(
    AddressAutocompleteOptions options,
  ) {
    throw UnimplementedError('suggestAddresses() has not been implemented.');
  }

  Future<ResolvedAddress?> resolveAddress(
    AddressSuggestion suggestion, {
    String? localeTag,
    int? requestId,
  }) {
    throw UnimplementedError('resolveAddress() has not been implemented.');
  }
}
