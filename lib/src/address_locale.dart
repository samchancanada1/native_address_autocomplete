import 'dart:ui';

String? localeToLanguageTag(Locale? locale) {
  if (locale == null) {
    return null;
  }

  final StringBuffer buffer = StringBuffer(locale.languageCode);
  if (locale.scriptCode != null && locale.scriptCode!.isNotEmpty) {
    buffer.write('-${locale.scriptCode}');
  }
  if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
    buffer.write('-${locale.countryCode}');
  }
  return buffer.toString();
}
