import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class Country {
  /// Resolves the current country code using system settings.
  static String get countryCode {
    final code = ui.PlatformDispatcher.instance.locale.countryCode;
    return (code == null || code.isEmpty) ? 'NL' : code.toUpperCase();
  }

  /// Centralized async lookup for resolving the country code.
  static Future<String> resolveCountryCode(BuildContext? context) async {
    var code = countryCode;
    if (code != 'NL') return code;

    // 1. Context check fallback
    if (context != null) {
      final contextCode = Localizations.maybeLocaleOf(context)?.countryCode;
      if (contextCode != null && contextCode.isNotEmpty) return contextCode.toUpperCase();
    }

    // 2. IP check fallback
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final fetchedCode = jsonDecode(response.body)['country_code'] as String?;
        if (fetchedCode != null && fetchedCode.isNotEmpty) return fetchedCode.toUpperCase();
      }
    } catch (_) {}

    return 'NL';
  }

  /// Standard 12-hour clock countries (US, UK, Canada, Australia, New Zealand, Philippines, India, Ireland).
  static bool get use24HourFormat =>
      !const {'US', 'GB', 'CA', 'AU', 'NZ', 'PH', 'IN', 'IE'}.contains(countryCode);
}
