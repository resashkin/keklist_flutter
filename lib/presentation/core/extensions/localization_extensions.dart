import 'package:flutter/material.dart';
import 'package:keklist/l10n/app_localizations.dart';
import 'package:keklist/l10n/app_localizations_en.dart';

/// Extension to simplify localization access
extension LocalizationExtension on BuildContext {
  /// Get localized strings with null safety
  AppLocalizations get l10n {
    return AppLocalizations.of(this) ?? AppLocalizationsEn();
  }
}
