import 'package:flutter/foundation.dart';

import 'address_suggestion.dart';
import 'resolved_address.dart';

/// Holds the live state of a [NativeAddressAutocompleteTextField].
///
/// Use this when a parent widget needs to observe the current suggestions,
/// loading state, selected suggestion, resolved address, or last error.
class AddressAutocompleteController extends ChangeNotifier {
  AddressSuggestion? get selectedSuggestion => _selectedSuggestion;
  AddressSuggestion? _selectedSuggestion;

  ResolvedAddress? get resolvedAddress => _resolvedAddress;
  ResolvedAddress? _resolvedAddress;

  List<AddressSuggestion> get suggestions =>
      List<AddressSuggestion>.unmodifiable(_suggestions);
  List<AddressSuggestion> _suggestions = <AddressSuggestion>[];

  bool get isLoading => _isLoading;
  bool _isLoading = false;

  Object? get error => _error;
  Object? _error;

  void clear() {
    _selectedSuggestion = null;
    _resolvedAddress = null;
    _suggestions = <AddressSuggestion>[];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void setSelectedSuggestion(AddressSuggestion? suggestion) {
    _selectedSuggestion = suggestion;
    if (suggestion == null) {
      _resolvedAddress = null;
    }
    notifyListeners();
  }

  void setResolvedAddress(ResolvedAddress? address) {
    _resolvedAddress = address;
    notifyListeners();
  }

  void setLoading(bool loading) {
    if (_isLoading == loading) {
      return;
    }
    _isLoading = loading;
    notifyListeners();
  }

  void setSuggestions(List<AddressSuggestion> suggestions) {
    _suggestions = List<AddressSuggestion>.unmodifiable(suggestions);
    notifyListeners();
  }

  void setError(Object? error) {
    _error = error;
    notifyListeners();
  }
}
