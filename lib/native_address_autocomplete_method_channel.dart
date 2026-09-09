import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_address_autocomplete_platform_interface.dart';
import 'src/address_autocomplete_options.dart';
import 'src/address_suggestion.dart';
import 'src/native_address_autocomplete_exception.dart';
import 'src/resolved_address.dart';

/// An implementation of [NativeAddressAutocompletePlatform] that uses method channels.
class MethodChannelNativeAddressAutocomplete
    extends NativeAddressAutocompletePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('native_address_autocomplete');

  @override
  Future<bool> isAvailable() async {
    try {
      return await methodChannel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      throw NativeAddressAutocompleteException(
        error.message ?? 'Address autocomplete availability check failed.',
        code: error.code,
      );
    }
  }

  @override
  Future<List<AddressSuggestion>> suggestAddresses(
    AddressAutocompleteOptions options,
  ) async {
    final List<Object?> rawSuggestions;
    try {
      rawSuggestions =
          await methodChannel.invokeMethod<List<Object?>>(
            'suggestAddresses',
            options.toMap(),
          ) ??
          <Object?>[];
    } on MissingPluginException {
      throw UnsupportedError(
        'native_address_autocomplete only supports Android and iOS.',
      );
    } on PlatformException catch (error) {
      throw NativeAddressAutocompleteException(
        error.message ?? 'Address autocomplete failed.',
        code: error.code,
      );
    }

    return rawSuggestions
        .whereType<Map<Object?, Object?>>()
        .map(AddressSuggestion.fromMap)
        .where((AddressSuggestion suggestion) => suggestion.fullText.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<ResolvedAddress?> resolveAddress(
    AddressSuggestion suggestion, {
    String? localeTag,
    int? requestId,
  }) async {
    final Map<String, Object?> arguments = suggestion.toMap();
    arguments['locale'] = localeTag;
    arguments['requestId'] = requestId;

    final Object? rawAddress;
    try {
      rawAddress = await methodChannel.invokeMethod<Object?>(
        'resolveAddress',
        arguments,
      );
    } on MissingPluginException {
      throw UnsupportedError(
        'native_address_autocomplete only supports Android and iOS.',
      );
    } on PlatformException catch (error) {
      throw NativeAddressAutocompleteException(
        error.message ?? 'Address resolve failed.',
        code: error.code,
      );
    }

    if (rawAddress is! Map<Object?, Object?>) {
      return null;
    }

    final ResolvedAddress resolvedAddress = ResolvedAddress.fromMap(rawAddress);
    if (resolvedAddress.fullText.isEmpty) {
      return null;
    }
    return resolvedAddress;
  }
}
