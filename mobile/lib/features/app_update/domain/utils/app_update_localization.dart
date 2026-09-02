import 'package:flutter/widgets.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

AppLocalizations appUpdateLocalizations(String localeCode) {
  final locale = localeCode.startsWith('en')
      ? const Locale('en')
      : const Locale('ar');
  return lookupAppLocalizations(locale);
}
