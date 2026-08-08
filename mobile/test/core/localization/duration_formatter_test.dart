import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/localization/duration_formatter.dart';
import 'package:mobile/core/localization/l10n/app_localizations.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  group('DurationFormatter English', () {
    test('formats decimal hours as hours and minutes', () {
      expect(DurationFormatter.fromHours(14.95, en), '14 hours 57 minutes');
      expect(DurationFormatter.fromHours(14.5, en), '14 hours 30 minutes');
      expect(DurationFormatter.fromHours(2.75, en), '2 hours 45 minutes');
      expect(DurationFormatter.fromHours(0.5, en), '30 minutes');
      expect(DurationFormatter.fromHours(1, en), '1 hour');
      expect(DurationFormatter.fromHours(0, en), '0 minutes');
    });

    test('formats minutes', () {
      expect(DurationFormatter.fromMinutes(0, en), '0 minutes');
      expect(DurationFormatter.fromMinutes(1, en), '1 minute');
      expect(DurationFormatter.fromMinutes(30, en), '30 minutes');
      expect(DurationFormatter.fromMinutes(60, en), '1 hour');
      expect(DurationFormatter.fromMinutes(897, en), '14 hours 57 minutes');
    });
  });

  group('DurationFormatter Arabic', () {
    test('formats decimal hours as hours and minutes', () {
      expect(DurationFormatter.fromHours(14.95, ar), '14 ساعة و 57 دقيقة');
      expect(DurationFormatter.fromHours(14.5, ar), '14 ساعة و 30 دقيقة');
      expect(DurationFormatter.fromHours(0.5, ar), '30 دقيقة');
      expect(DurationFormatter.fromHours(1, ar), 'ساعة واحدة');
      expect(DurationFormatter.fromHours(0, ar), '0 دقيقة');
    });
  });
}
