import 'package:flutter/foundation.dart';

import 'address_suggestion.dart';
import 'resolved_address.dart';

/// Holds the live state of a [NativeAddressAutocompleteTextField].
///
/// Use this when a parent widget needs to observe the current suggestions,
/// loading state, selected suggestion, resolved address, or last error.
class AddressAutocompleteController extends ChangeNotifier {
  /// Creates an address autocomplete state controller.
  AddressAutocompleteController();

  /// The most recent suggestion selected by the user.
  AddressSuggestion? get selectedSuggestion => _selectedSuggestion;
  AddressSuggestion? _selectedSuggestion;

  /// The resolved address for [selectedSuggestion], when resolution succeeds.
  ResolvedAddress? get resolvedAddress => _resolvedAddress;
  ResolvedAddress? _resolvedAddress;

  /// Current suggestions shown by the widget.
  List<AddressSuggestion> get suggestions =>
      List<AddressSuggestion>.unmodifiable(_suggestions);
  List<AddressSuggestion> _suggestions = <AddressSuggestion>[];

  /// Whether the widget is currently waiting for native suggestions.
  bool get isLoading => _isLoading;
  bool _isLoading = false;

  /// The latest error reported by suggestion loading or resolution.
  Object? get error => _error;
  Object? _error;

  /// Clears selected, resolved, suggestion, loading, and error state.
  void clear() {
    _selectedSuggestion = null;
    _resolvedAddress = null;
    _suggestions = <AddressSuggestion>[];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Sets the currently selected suggestion.
  void setSelectedSuggestion(AddressSuggestion? suggestion) {
    _selectedSuggestion = suggestion;
    if (suggestion == null) {
      _resolvedAddress = null;
    }
    notifyListeners();
  }

  /// Sets the currently resolved address.
  void setResolvedAddress(ResolvedAddress? address) {
    _resolvedAddress = address;
    notifyListeners();
  }

  /// Sets whether a native request is in progress.
  void setLoading(bool loading) {
    if (_isLoading == loading) {
      return;
    }
    _isLoading = loading;
    notifyListeners();
  }

  /// Replaces the current suggestions.
  void setSuggestions(List<AddressSuggestion> suggestions) {
    _suggestions = List<AddressSuggestion>.unmodifiable(suggestions);
    notifyListeners();
  }

  /// Sets the latest error.
  void setError(Object? error) {
    _error = error;
    notifyListeners();
  }
}
