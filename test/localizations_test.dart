import 'dart:ui';

import 'package:durations/localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import "package:test/test.dart";

void main() {

  group("translations", () {

    void expectNoMissingMessages(CustomLocalizations lang) {
      for (var key in MessageKey.values) {
        expect(lang.message(key), isNotEmpty, reason: "message for $key");
      }
    }

    test("en", () {
      var en = CustomLocalizations(Locale("en"));
      expect(en.message(MessageKey.add), equals("Add"));
      expectNoMissingMessages(en);
    });

    test("de_CH", () {
      var de = CustomLocalizations(Locale("de", "CH"));
      expect(de.message(MessageKey.add), equals("Hinzufügen"));
      expectNoMissingMessages(de);
    });

    test("fr", () {
      var fr = CustomLocalizations(Locale("fr"));
      expect(fr.message(MessageKey.add), equals("Ajouter"));
      expectNoMissingMessages(fr);
    });
  });

  group("format durations", () {

    var en = CustomLocalizations(Locale("en"));

    test("never", () {
      expect(en.formatDuration(null), equals("never"));
      expect(() => en.formatDuration(null, relative: true), throwsArgumentError);
    });

    test("less than a minute ago", () {
      var duration = Duration(seconds: 59);
      expect(en.formatDuration(duration), equals("just now"));
      expect(en.formatDuration(duration, relative: true), equals("immediatly"));
    });

    test("one minute ago", () {
      var duration = Duration(minutes: 1);
      expect(en.formatDuration(duration), equals("1 minute ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 minute"));
    });

    test("just over a minute ago", () {
      var duration = Duration(minutes: 1, seconds: 1);
      expect(en.formatDuration(duration), equals("1 minute ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 minute"));
    });

    test("ten minutes ago", () {
      var duration = Duration(minutes: 10);
      expect(en.formatDuration(duration), equals("10 minutes ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 10 minutes"));
    });

    test("one hour ago", () {
      var duration = Duration(hours: 1);
      expect(en.formatDuration(duration), equals("1 hour ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 hour"));
    });

    test("just over an hour ago", () {
      var duration = Duration(hours: 1, minutes: 1, seconds: 1);
      expect(en.formatDuration(duration), equals("1 hour and 1 minute ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 hour and 1 minute"));
    });

    test("two hours ago", () {
      var duration = Duration(hours: 2);
      expect(en.formatDuration(duration), equals("2 hours ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 2 hours"));
    });

    test("one day ago", () {
      var duration = Duration(days: 1);
      expect(en.formatDuration(duration), equals("1 day ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 day"));
    });

    test("one day and one hour ago", () {
      var duration = Duration(days: 1, hours: 1);
      expect(en.formatDuration(duration), equals("1 day and 1 hour ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 day and 1 hour"));
    });

    test("two days ago", () {
      var duration = Duration(days: 2);
      expect(en.formatDuration(duration), equals("2 days ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 2 days"));
    });

    test("one week ago", () {
      var duration = Duration(days: 7);
      expect(en.formatDuration(duration), equals("1 week ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 week"));
    });

    test("just over a week ago", () {
      var duration = Duration(days: 7, hours: 6, minutes: 5);
      expect(en.formatDuration(duration), equals("1 week and 6 hours ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 week and 6 hours"));
    });

    test("one week ago and one day ago", () {
      var duration = Duration(days: 8);
      expect(en.formatDuration(duration), equals("1 week and 1 day ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 1 week and 1 day"));
    });

    test("two weeks ago", () {
      var duration = Duration(days: 14);
      expect(en.formatDuration(duration), equals("2 weeks ago"));
      expect(en.formatDuration(duration, relative: true), equals("after 2 weeks"));
    });

    test("in the future", () {
      var duration = Duration(days: -1);
      expect(en.formatDuration(duration), equals("not yet"));
      expect(() => en.formatDuration(duration, relative: true), throwsArgumentError);
    });
  });

  group("format short date", () {

    final date = DateTime(2020, 1, 31);

    setUpAll(() async {
      await initializeDateFormatting();
    });

    String formatShortDate(String locale) {
      var localizations = CustomLocalizations(Locale(locale));
      return localizations.formatShortDate(date);
    }

    test("en", () {
      expect(formatShortDate("en"), "1/31/2020");
    });

    test("en_GB", () {
      expect(formatShortDate("en_GB"), "31/01/2020");
    });

    test("de", () {
      expect(formatShortDate("de"), "31.1.2020");
    });

    test("fr", () {
      expect(formatShortDate("fr"), "31/01/2020");
    });

    test("fr_CH", () {
      expect(formatShortDate("fr_CH"), "31.01.2020");
    });
  });
}
