import 'package:flutter/material.dart';

import 'address_autocomplete_controller.dart';
import 'address_result_type.dart';
import 'address_suggestion.dart';
import 'native_address_autocomplete_client.dart';
import 'native_address_autocomplete_text_field.dart';
import 'resolved_address.dart';

/// A [FormField] wrapper around [NativeAddressAutocompleteTextField].
///
/// The field value is the resolved address. By default this widget resolves the
/// selected suggestion before calling validation or save callbacks.
class NativeAddressAutocompleteFormField extends FormField<ResolvedAddress> {
  NativeAddressAutocompleteFormField({
    super.key,
    AddressAutocompleteController? addressController,
    TextEditingController? controller,
    FocusNode? focusNode,
    NativeAddressAutocomplete provider = const NativeAddressAutocomplete(),
    InputDecoration decoration = const InputDecoration(),
    TextStyle? style,
    bool? enabled,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    int minChars = 3,
    Duration debounce = const Duration(milliseconds: 350),
    int limit = 5,
    List<String> countries = const <String>[],
    double? latitude,
    double? longitude,
    double? radiusMeters,
    Set<AddressResultType> resultTypes = const <AddressResultType>{
      AddressResultType.address,
      AddressResultType.pointOfInterest,
    },
    Locale? locale,
    bool useSystemLocale = true,
    double dropdownMaxHeight = 280,
    AddressSuggestionItemBuilder? itemBuilder,
    AddressSuggestionsBuilder? suggestionsBuilder,
    WidgetBuilder? loadingBuilder,
    WidgetBuilder? loadingIndicatorBuilder,
    bool showLoadingIndicator = true,
    bool showClearButton = false,
    WidgetBuilder? clearButtonBuilder,
    WidgetBuilder? emptyBuilder,
    AddressAutocompleteErrorBuilder? errorBuilder,
    ValueChanged<String>? onChanged,
    ValueChanged<AddressSuggestion>? onSelected,
    bool resolveOnSelected = true,
    ValueChanged<ResolvedAddress>? onResolved,
    ValueChanged<Object>? onError,
    bool highlightMatches = true,
    String clearTooltip = 'Clear',
    String emptyText = '',
    String errorText = 'Unable to load address suggestions.',
    TapRegionCallback? onTapOutside,
    AddressAutocompleteDebounceFactory debounceTimerFactory =
        defaultAddressAutocompleteDebounceFactory,
    super.onSaved,
    super.validator,
    super.initialValue,
    super.autovalidateMode,
  }) : super(
          enabled: enabled ?? true,
          builder: (FormFieldState<ResolvedAddress> field) {
            final InputDecoration effectiveDecoration = decoration.copyWith(
              errorText: field.errorText,
            );
            return NativeAddressAutocompleteTextField(
              addressController: addressController,
              controller: controller,
              focusNode: focusNode,
              provider: provider,
              decoration: effectiveDecoration,
              style: style,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              minChars: minChars,
              debounce: debounce,
              limit: limit,
              countries: countries,
              latitude: latitude,
              longitude: longitude,
              radiusMeters: radiusMeters,
              resultTypes: resultTypes,
              locale: locale,
              useSystemLocale: useSystemLocale,
              dropdownMaxHeight: dropdownMaxHeight,
              itemBuilder: itemBuilder,
              suggestionsBuilder: suggestionsBuilder,
              loadingBuilder: loadingBuilder,
              loadingIndicatorBuilder: loadingIndicatorBuilder,
              showLoadingIndicator: showLoadingIndicator,
              showClearButton: showClearButton,
              clearButtonBuilder: clearButtonBuilder,
              emptyBuilder: emptyBuilder,
              errorBuilder: errorBuilder,
              onChanged: onChanged,
              onSelected: onSelected,
              resolveOnSelected: resolveOnSelected,
              onResolved: (ResolvedAddress address) {
                field.didChange(address);
                onResolved?.call(address);
              },
              onError: onError,
              highlightMatches: highlightMatches,
              clearTooltip: clearTooltip,
              emptyText: emptyText,
              errorText: errorText,
              onTapOutside: onTapOutside,
              debounceTimerFactory: debounceTimerFactory,
            );
          },
        );
}
