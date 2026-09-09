import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'address_autocomplete_controller.dart';
import 'address_locale.dart';
import 'address_result_type.dart';
import 'address_suggestion.dart';
import 'native_address_autocomplete_client.dart';
import 'resolved_address.dart';

/// Builds the UI for one address suggestion.
typedef AddressSuggestionItemBuilder =
    Widget Function(
      BuildContext context,
      AddressSuggestion suggestion,
      int index,
    );

/// Builds the suggestions dropdown body.
///
/// The provided `itemBuilder` already handles hover, keyboard highlight, and
/// tap-to-select wrapping.
typedef AddressSuggestionsBuilder =
    Widget Function(
      BuildContext context,
      List<AddressSuggestion> suggestions,
      AddressSuggestionItemBuilder itemBuilder,
    );

/// Builds the dropdown error state.
typedef AddressAutocompleteErrorBuilder =
    Widget Function(BuildContext context, Object error);

/// Creates the timer used to debounce native autocomplete requests.
typedef AddressAutocompleteDebounceFactory =
    Timer Function(Duration duration, VoidCallback callback);

/// Default debounce timer factory.
Timer defaultAddressAutocompleteDebounceFactory(
  Duration duration,
  VoidCallback callback,
) {
  return Timer(duration, callback);
}

/// A TextField-style address autocomplete widget backed by native platform APIs.
///
/// The widget owns debouncing, loading/error/empty dropdown states, keyboard
/// navigation, optional clear/loading suffix controls, and optional resolution
/// of the selected suggestion.
class NativeAddressAutocompleteTextField extends StatefulWidget {
  const NativeAddressAutocompleteTextField({
    super.key,
    this.addressController,
    this.controller,
    this.focusNode,
    this.provider = const NativeAddressAutocomplete(),
    this.decoration = const InputDecoration(),
    this.style,
    this.enabled,
    this.keyboardType,
    this.textInputAction,
    this.minChars = 3,
    this.debounce = const Duration(milliseconds: 350),
    this.limit = 5,
    this.countries = const <String>[],
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.resultTypes = const <AddressResultType>{
      AddressResultType.address,
      AddressResultType.pointOfInterest,
    },
    this.locale,
    this.useSystemLocale = true,
    this.dropdownMaxHeight = 280,
    this.itemBuilder,
    this.suggestionsBuilder,
    this.loadingBuilder,
    this.loadingIndicatorBuilder,
    this.showLoadingIndicator = true,
    this.showClearButton = false,
    this.clearButtonBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.onChanged,
    this.onSelected,
    this.resolveOnSelected = false,
    this.onResolved,
    this.onError,
    this.highlightMatches = true,
    this.clearTooltip = 'Clear',
    this.emptyText = '',
    this.errorText = 'Unable to load address suggestions.',
    this.onTapOutside,
    this.debounceTimerFactory = defaultAddressAutocompleteDebounceFactory,
  });

  final AddressAutocompleteController? addressController;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final NativeAddressAutocomplete provider;
  final InputDecoration decoration;
  final TextStyle? style;
  final bool? enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int minChars;
  final Duration debounce;
  final int limit;
  final List<String> countries;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;
  final Set<AddressResultType> resultTypes;
  final Locale? locale;
  final bool useSystemLocale;
  final double dropdownMaxHeight;
  final AddressSuggestionItemBuilder? itemBuilder;
  final AddressSuggestionsBuilder? suggestionsBuilder;
  final WidgetBuilder? loadingBuilder;
  final WidgetBuilder? loadingIndicatorBuilder;
  final bool showLoadingIndicator;
  final bool showClearButton;
  final WidgetBuilder? clearButtonBuilder;
  final WidgetBuilder? emptyBuilder;
  final AddressAutocompleteErrorBuilder? errorBuilder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<AddressSuggestion>? onSelected;
  final bool resolveOnSelected;
  final ValueChanged<ResolvedAddress>? onResolved;
  final ValueChanged<Object>? onError;
  final bool highlightMatches;
  final String clearTooltip;
  final String emptyText;
  final String errorText;
  final TapRegionCallback? onTapOutside;
  final AddressAutocompleteDebounceFactory debounceTimerFactory;

  @override
  State<NativeAddressAutocompleteTextField> createState() =>
      _NativeAddressAutocompleteTextFieldState();
}

class _NativeAddressAutocompleteTextFieldState
    extends State<NativeAddressAutocompleteTextField> {
  static const double _dropdownGap = 4;

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AddressAutocompleteController _addressController;
  late final bool _ownsAddressController;
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;
  List<AddressSuggestion> _suggestions = <AddressSuggestion>[];
  bool _loading = false;
  Object? _error;
  int _requestId = 0;
  int _highlightedIndex = -1;
  String _query = '';
  late String _lastControllerText;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsAddressController = widget.addressController == null;
    _addressController =
        widget.addressController ?? AddressAutocompleteController();
    _lastControllerText = _controller.text;
    _focusNode.addListener(_handleFocusChanged);
    _controller.addListener(_handleControllerTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _removeOverlay();
    _controller.removeListener(_handleControllerTextChanged);
    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (_ownsAddressController) {
      _addressController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            CompositedTransformTarget(
              key: _fieldKey,
              link: _layerLink,
              child: Focus(
                onKeyEvent: _handleKeyEvent,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: _effectiveDecoration(context),
                  style: widget.style,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onChanged: _handleChanged,
                  onSubmitted: (_) => _selectHighlightedSuggestion(),
                  onTapOutside: (PointerDownEvent event) {
                    _removeOverlay();
                    widget.onTapOutside?.call(event);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _effectiveDecoration(BuildContext context) {
    final List<Widget> suffixWidgets = <Widget>[
      if (widget.showLoadingIndicator && _loading)
        widget.loadingIndicatorBuilder?.call(context) ??
            const SizedBox(
              width: 44,
              child: Center(
                child: SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
              ),
            ),
      if (widget.showClearButton && _controller.text.isNotEmpty)
        widget.clearButtonBuilder?.call(context) ??
            IconButton(
              tooltip: widget.clearTooltip,
              icon: const Icon(Icons.clear),
              onPressed: _clear,
            ),
      if (widget.decoration.suffixIcon != null) widget.decoration.suffixIcon!,
    ];

    if (suffixWidgets.isEmpty) {
      return widget.decoration;
    }

    return widget.decoration.copyWith(
      suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: suffixWidgets),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _suggestions.isEmpty) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _setHighlightedIndex((_highlightedIndex + 1) % _suggestions.length);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final int previousIndex = _highlightedIndex <= 0
          ? _suggestions.length - 1
          : _highlightedIndex - 1;
      _setHighlightedIndex(previousIndex);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      return _selectHighlightedSuggestion()
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _removeOverlay();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _setHighlightedIndex(int index) {
    setState(() {
      _highlightedIndex = index;
    });
    _overlayEntry?.markNeedsBuild();
  }

  bool _selectHighlightedSuggestion() {
    if (_highlightedIndex < 0 || _highlightedIndex >= _suggestions.length) {
      return false;
    }
    _selectSuggestion(_suggestions[_highlightedIndex]);
    return true;
  }

  void _handleControllerTextChanged() {
    if (_controller.text == _lastControllerText) {
      return;
    }
    _lastControllerText = _controller.text;
    if (widget.showClearButton && mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (_focusNode.hasFocus) {
      _refreshOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);
    _debounceTimer?.cancel();
    _requestId++;
    _query = value;
    _error = null;
    _highlightedIndex = -1;
    _addressController.setSelectedSuggestion(null);
    _addressController.setResolvedAddress(null);
    _addressController.setError(null);

    if (value.trim().length < widget.minChars) {
      setState(() {
        _loading = false;
        _suggestions = <AddressSuggestion>[];
      });
      _addressController.setLoading(false);
      _addressController.setSuggestions(<AddressSuggestion>[]);
      _removeOverlay();
      return;
    }

    setState(() {
      _loading = true;
    });
    _addressController.setLoading(true);
    _refreshOverlay();

    _debounceTimer = widget.debounceTimerFactory(widget.debounce, () {
      _loadSuggestions(value);
    });
  }

  Future<void> _loadSuggestions(String query) async {
    final int currentRequest = ++_requestId;
    try {
      final List<AddressSuggestion> suggestions = await widget.provider.suggest(
        query,
        countries: widget.countries,
        limit: widget.limit,
        latitude: widget.latitude,
        longitude: widget.longitude,
        radiusMeters: widget.radiusMeters,
        resultTypes: widget.resultTypes,
        localeTag: _localeTag,
        requestId: currentRequest,
      );

      if (!mounted || currentRequest != _requestId) {
        return;
      }

      setState(() {
        _loading = false;
        _error = null;
        _suggestions = suggestions;
        _highlightedIndex = suggestions.isEmpty ? -1 : 0;
      });
      _addressController.setLoading(false);
      _addressController.setError(null);
      _addressController.setSuggestions(suggestions);
      _refreshOverlay();
    } catch (error) {
      if (!mounted || currentRequest != _requestId) {
        return;
      }
      widget.onError?.call(error);
      setState(() {
        _loading = false;
        _error = error;
        _suggestions = <AddressSuggestion>[];
        _highlightedIndex = -1;
      });
      _addressController.setLoading(false);
      _addressController.setError(error);
      _addressController.setSuggestions(<AddressSuggestion>[]);
      _refreshOverlay();
    }
  }

  Future<void> _selectSuggestion(AddressSuggestion suggestion) async {
    _controller.text = suggestion.fullText;
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    _addressController.setSelectedSuggestion(suggestion);
    widget.onSelected?.call(suggestion);
    _removeOverlay();
    _focusNode.unfocus();

    if (!widget.resolveOnSelected && widget.onResolved == null) {
      return;
    }

    try {
      final ResolvedAddress? resolvedAddress = await widget.provider.resolve(
        suggestion,
        localeTag: _localeTag,
        requestId: ++_requestId,
      );
      if (resolvedAddress != null) {
        _addressController.setResolvedAddress(resolvedAddress);
        widget.onResolved?.call(resolvedAddress);
      }
    } catch (error) {
      _addressController.setError(error);
      widget.onError?.call(error);
    }
  }

  void _clear() {
    _debounceTimer?.cancel();
    _requestId++;
    _controller.clear();
    widget.onChanged?.call('');
    _addressController.clear();
    setState(() {
      _loading = false;
      _error = null;
      _suggestions = <AddressSuggestion>[];
      _highlightedIndex = -1;
      _query = '';
    });
    _removeOverlay();
  }

  String? get _localeTag {
    final Locale? locale =
        widget.locale ??
        (widget.useSystemLocale ? Localizations.maybeLocaleOf(context) : null);
    return localeToLanguageTag(locale);
  }

  void _refreshOverlay() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
      return;
    }

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(builder: _buildOverlay);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  Widget _buildOverlay(BuildContext context) {
    final BuildContext? fieldContext = _fieldKey.currentContext;
    if (fieldContext == null) {
      return const SizedBox.shrink();
    }
    final RenderBox box = fieldContext.findRenderObject()! as RenderBox;
    final Size size = box.size;
    final Offset targetOffset = box.localToGlobal(Offset.zero);
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double availableHeight = math.max(
      0,
      mediaQuery.size.height -
          mediaQuery.padding.bottom -
          targetOffset.dy -
          size.height -
          _dropdownGap,
    );
    final double maxHeight = math.min(
      widget.dropdownMaxHeight,
      availableHeight,
    );

    if (maxHeight <= 0) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: targetOffset.dx,
      top: targetOffset.dy + size.height + _dropdownGap,
      width: size.width,
      child: _buildDropdown(context, maxHeight),
    );
  }

  Widget _buildDropdown(BuildContext context, double maxHeight) {
    Widget child;
    if (_loading) {
      child =
          widget.loadingBuilder?.call(context) ??
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator.adaptive()),
          );
    } else if (_error != null) {
      child =
          widget.errorBuilder?.call(context, _error!) ??
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.errorText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
    } else if (_suggestions.isEmpty) {
      child =
          widget.emptyBuilder?.call(context) ??
          (widget.emptyText.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(widget.emptyText),
                ));
    } else {
      final AddressSuggestionItemBuilder contentBuilder =
          widget.itemBuilder ?? _defaultItemBuilder;
      Widget itemBuilder(
        BuildContext context,
        AddressSuggestion suggestion,
        int index,
      ) {
        final bool highlighted = index == _highlightedIndex;
        return Material(
          color: highlighted
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: () => _selectSuggestion(suggestion),
            onHover: (bool hovering) {
              if (hovering) {
                _setHighlightedIndex(index);
              }
            },
            child: contentBuilder(context, suggestion, index),
          ),
        );
      }

      child =
          widget.suggestionsBuilder?.call(context, _suggestions, itemBuilder) ??
          ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (BuildContext context, int index) {
              return itemBuilder(context, _suggestions[index], index);
            },
          );
    }

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: child,
      ),
    );
  }

  Widget _defaultItemBuilder(
    BuildContext context,
    AddressSuggestion suggestion,
    int index,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _highlightedText(
            suggestion.primaryText,
            _query,
            textTheme.bodyLarge,
            maxLines: 1,
          ),
          if (suggestion.secondaryText?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: _highlightedText(
                suggestion.secondaryText!,
                _query,
                textTheme.bodySmall,
                maxLines: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _highlightedText(
    String text,
    String query,
    TextStyle? style, {
    int? maxLines,
  }) {
    if (!widget.highlightMatches || query.trim().isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.trim().toLowerCase();
    final int matchIndex = lowerText.indexOf(lowerQuery);
    if (matchIndex < 0) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    final TextStyle effectiveStyle = style ?? const TextStyle();
    return Text.rich(
      TextSpan(
        style: effectiveStyle,
        children: <TextSpan>[
          TextSpan(text: text.substring(0, matchIndex)),
          TextSpan(
            text: text.substring(matchIndex, matchIndex + query.trim().length),
            style: effectiveStyle.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text.substring(matchIndex + query.trim().length)),
        ],
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
