import 'dart:ui';

import 'package:durations/localizations.dart';
import "package:test/test.dart";

void main() {

  group("translations", () {

    test("english", () {
      var en = CustomLocalizations(Locale("en"));
      expect(en.addButtonTooltip, equals("Add"));
    });

    test("german", () {
      var en = CustomLocalizations(Locale("de", "CH"));
      expect(en.addButtonTooltip, equals("Hinzufügen"));
    });

    test("french", () {
      var fr = CustomLocalizations(Locale("fr"));
      expect(fr.addButtonTooltip, equals("Ajouter"));
    });

  });

  group("format duration", () {

    var en = CustomLocalizations(Locale("en"));

    test("never", () {
      expect(en.formatDuration(null), equals("never"));
    });

    test("less than a minute ago", () {
      expect(en.formatDuration(Duration(seconds: 59)), equals("just now"));
    });

    test("one minute ago", () {
      expect(en.formatDuration(Duration(minutes: 1)), equals("1 minute ago"));
    });

    test("just over a minute ago", () {
      expect(en.formatDuration(Duration(minutes: 1, seconds: 1)), equals("1 minute ago"));
    });

    test("ten minutes ago", () {
      expect(en.formatDuration(Duration(minutes: 10)), equals("10 minutes ago"));
    });

    test("one hour ago", () {
      expect(en.formatDuration(Duration(hours: 1)), equals("1 hour ago"));
    });

    test("two hours ago", () {
      expect(en.formatDuration(Duration(hours: 2)), equals("2 hours ago"));
    });

    test("one day ago", () {
      expect(en.formatDuration(Duration(days: 1)), equals("1 day ago"));
    });

    test("one day and one hour ago", () {
      expect(en.formatDuration(Duration(days: 1, hours: 1)), equals("1 day ago"));
    });

    test("two days ago", () {
      expect(en.formatDuration(Duration(days: 2)), equals("2 days ago"));
    });

    test("one week ago", () {
      expect(en.formatDuration(Duration(days: 7)), equals("1 week ago"));
    });

    test("one week ago and one day ago", () {
      expect(en.formatDuration(Duration(days: 8)), equals("1 week ago"));
    });

    test("two weeks ago", () {
      expect(en.formatDuration(Duration(days: 15)), equals("2 weeks ago"));
    });

    test("in the future", () {
      expect(en.formatDuration(Duration(days: -1)), equals("sometime"));
    });
  });
}
