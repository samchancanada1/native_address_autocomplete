import 'package:flutter/material.dart';
import 'package:native_address_autocomplete/native_address_autocomplete.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AddressSearchPage(),
    );
  }
}

class AddressSearchPage extends StatefulWidget {
  const AddressSearchPage({super.key});

  @override
  State<AddressSearchPage> createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _fullTextController = TextEditingController();
  final TextEditingController _styledResultsController =
      TextEditingController();
  final TextEditingController _customLoadingController =
      TextEditingController();
  final AddressAutocompleteController _addressController =
      AddressAutocompleteController();
  final NativeAddressAutocomplete _autocomplete =
      const NativeAddressAutocomplete();
  AddressSuggestion? _selectedSuggestion;
  ResolvedAddress? _resolvedAddress;
  AddressSuggestion? _fullTextSuggestion;
  Object? _lastError;
  bool? _isAvailable;
  int _limit = 5;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _fullTextController.dispose();
    _styledResultsController.dispose();
    _customLoadingController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    final bool isAvailable = await _autocomplete.isAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      _isAvailable = isAvailable;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native address autocomplete')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            NativeAddressAutocompleteTextField(
              addressController: _addressController,
              controller: _controller,
              provider: _autocomplete,
              countries: const <String>['US', 'CA'],
              limit: _limit,
              minChars: 3,
              dropdownMaxHeight: 320,
              showClearButton: true,
              resolveOnSelected: true,
              useSystemLocale: true,
              clearTooltip: 'Clear address',
              emptyText: 'No addresses found.',
              errorText: 'Could not load suggestions.',
              resultTypes: const <AddressResultType>{
                AddressResultType.address,
                AddressResultType.pointOfInterest,
              },
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Start typing an address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              itemBuilder:
                  (
                    BuildContext context,
                    AddressSuggestion suggestion,
                    int index,
                  ) {
                    return ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(
                        suggestion.primaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: suggestion.secondaryText == null
                          ? null
                          : Text(
                              suggestion.secondaryText!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    );
                  },
              onChanged: (String value) {
                _clearAddressParts();
                setState(() {
                  _selectedSuggestion = null;
                  _resolvedAddress = null;
                  _lastError = null;
                });
              },
              onSelected: (AddressSuggestion suggestion) {
                _controller.text = suggestion.primaryText;
                _cityController.text = suggestion.city ?? '';
                _stateController.text = suggestion.state ?? '';
                _postalCodeController.text = suggestion.postalCode ?? '';
                _countryController.text = suggestion.country ?? '';

                setState(() {
                  _selectedSuggestion = suggestion;
                  _resolvedAddress = null;
                  _lastError = null;
                });
              },
              onResolved: (ResolvedAddress address) {
                _cityController.text = address.city ?? '';
                _stateController.text = address.state ?? '';
                _postalCodeController.text = address.postalCode ?? '';
                _countryController.text = address.country ?? '';

                setState(() {
                  _resolvedAddress = address;
                });
              },
              onError: (Object error) {
                setState(() {
                  _lastError = error;
                });
              },
              errorBuilder: (BuildContext context, Object error) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Could not load suggestions.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: _fieldDecoration('City'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stateController,
              decoration: _fieldDecoration('State / Province'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _postalCodeController,
              decoration: _fieldDecoration('Postal code'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _countryController,
              decoration: _fieldDecoration('Country'),
            ),
            const SizedBox(height: 24),
            Text(
              'Full text example',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            NativeAddressAutocompleteTextField(
              controller: _fullTextController,
              provider: _autocomplete,
              countries: const <String>['US', 'CA'],
              limit: _limit,
              minChars: 3,
              showClearButton: true,
              clearTooltip: 'Clear full address',
              decoration: const InputDecoration(
                labelText: 'Full address',
                hintText: 'This field keeps suggestion.fullText',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home_outlined),
              ),
              onChanged: (String value) {
                if (value.isEmpty) {
                  setState(() {
                    _fullTextSuggestion = null;
                  });
                }
              },
              onSelected: (AddressSuggestion suggestion) {
                setState(() {
                  _fullTextSuggestion = suggestion;
                });
              },
            ),
            if (_fullTextSuggestion != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Selected: ${_fullTextSuggestion!.fullText}'),
              ),
            const SizedBox(height: 24),
            Text(
              'Styled results example',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            NativeAddressAutocompleteTextField(
              controller: _styledResultsController,
              provider: _autocomplete,
              countries: const <String>['US', 'CA'],
              limit: _limit,
              minChars: 3,
              showClearButton: true,
              dropdownMaxHeight: 260,
              decoration: const InputDecoration(
                labelText: 'Styled address',
                hintText: 'Custom result rows and dropdown surface',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.palette_outlined),
              ),
              suggestionsBuilder:
                  (
                    BuildContext context,
                    List<AddressSuggestion> suggestions,
                    AddressSuggestionItemBuilder itemBuilder,
                  ) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: suggestions.length,
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider(
                            height: 1,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          );
                        },
                        itemBuilder: (BuildContext context, int index) {
                          return itemBuilder(
                            context,
                            suggestions[index],
                            index,
                          );
                        },
                      ),
                    );
                  },
              itemBuilder:
                  (
                    BuildContext context,
                    AddressSuggestion suggestion,
                    int index,
                  ) {
                    final ColorScheme colors = Theme.of(context).colorScheme;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: <Widget>[
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: colors.primaryContainer,
                            foregroundColor: colors.onPrimaryContainer,
                            child: const Icon(Icons.location_on_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  suggestion.primaryText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (suggestion.secondaryText != null)
                                  Text(
                                    suggestion.secondaryText!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.north_east, size: 18),
                        ],
                      ),
                    );
                  },
            ),
            const SizedBox(height: 24),
            Text(
              'Custom loading example',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            NativeAddressAutocompleteTextField(
              controller: _customLoadingController,
              provider: _autocomplete,
              countries: const <String>['US', 'CA'],
              limit: _limit,
              minChars: 3,
              showClearButton: true,
              decoration: const InputDecoration(
                labelText: 'Loading style address',
                hintText: 'Custom trailing and dropdown loading',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.hourglass_top_outlined),
              ),
              loadingIndicatorBuilder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              },
              loadingBuilder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text('Searching native address results...'),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              _isAvailable == null
                  ? 'Checking native geocoder...'
                  : 'Native geocoder available: $_isAvailable',
            ),
            const SizedBox(height: 16),
            Text('Results shown: $_limit'),
            Slider(
              value: _limit.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: '$_limit',
              onChanged: (double value) {
                setState(() {
                  _limit = value.round();
                });
              },
            ),
            const SizedBox(height: 16),
            if (_lastError != null)
              Text(
                'Last error: $_lastError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_lastError != null) const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _addressController,
              builder: (BuildContext context, Widget? child) {
                return Text(
                  'Controller state: '
                  '${_addressController.isLoading ? 'loading' : 'idle'}, '
                  '${_addressController.suggestions.length} suggestions',
                );
              },
            ),
            const SizedBox(height: 16),
            if (_selectedSuggestion != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _selectedSuggestion!.fullText,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_resolvedAddress != null) ...<Widget>[
                        const SizedBox(height: 12),
                        _AddressLine('Street', _resolvedAddress!.street),
                        _AddressLine('City', _resolvedAddress!.city),
                        _AddressLine('State', _resolvedAddress!.state),
                        _AddressLine(
                          'Postal code',
                          _resolvedAddress!.postalCode,
                        ),
                        _AddressLine('Country', _resolvedAddress!.country),
                      ],
                      if ((_resolvedAddress?.latitude ??
                                  _selectedSuggestion!.latitude) !=
                              null &&
                          (_resolvedAddress?.longitude ??
                                  _selectedSuggestion!.longitude) !=
                              null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${_resolvedAddress?.latitude ?? _selectedSuggestion!.latitude}, '
                            '${_resolvedAddress?.longitude ?? _selectedSuggestion!.longitude}',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );
  }

  void _clearAddressParts() {
    _cityController.clear();
    _stateController.clear();
    _postalCodeController.clear();
    _countryController.clear();
  }
}

class _AddressLine extends StatelessWidget {
  const _AddressLine(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text('$label: $value'),
    );
  }
}
