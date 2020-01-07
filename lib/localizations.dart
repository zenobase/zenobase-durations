import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiver/check.dart';
import 'package:sprintf/sprintf.dart';

class CustomLocalizations {

  final Locale _locale;

  CustomLocalizations(this._locale);

  static CustomLocalizations of(BuildContext context) {
    return Localizations.of<CustomLocalizations>(context, CustomLocalizations);
  }

  String message(String key) => const {
    "en": {
      "title": "Durations",
      "label_field_hint": "Label",
      "add_button_tooltip": "Add",
      "remove_button_tooltip": "Remove",
      "export_menu_item": "Export...",
      "undo_label": "Undo",
      "event_added": "Logged an event.",
      "event_updated": "Updated an event.",
      "event_removed": "Removed an event.",
      "bucket_removed": "Removed a series.",
      "duration_never": "never",
      "duration_now": "just now",
      "duration_future": "not yet",
      "duration_instantly": "immediatly",
      "duration_one_week": "1 week",
      "duration_one_day": "1 day",
      "duration_one_hour": "1 hour",
      "duration_one_minute": "1 minute",
      "duration_weeks": "%d weeks",
      "duration_days": "%d days",
      "duration_hours": "%d hours",
      "duration_minutes": "%d minutes",
      "duration_absolute": "%s ago",
      "duration_relative": "after %s",
    },
    "de": {
      "title": "Durations",
      "label_field_hint": "Label",
      "add_button_tooltip": "Hinzufügen",
      "remove_button_tooltip": "Löschen",
      "export_menu_item": "Exportieren...",
      "undo_label": "Rückgängig machen",
      "event_added": "Ein Ereignis wurde hinzugefügt.",
      "event_updated": "Ein Ereignis wurde aktualisiert.",
      "event_removed": "Ein Ereignis wurde gelöscht.",
      "bucket_removed": "Eine Serie wurde gelöscht.",
      "duration_never": "noch nie",
      "duration_now": "jetzt",
      "duration_instantly": "sofort",
      "duration_future": "noch nicht",
      "duration_one_week": "1 Woche",
      "duration_one_day": "1 Tag",
      "duration_one_hour": "1 Stunde",
      "duration_one_minute": "1 Minute",
      "duration_weeks": "%d Wochen",
      "duration_days": "%d Tagen",
      "duration_hours": "%d Stunden",
      "duration_minutes": "%d Minuten",
      "duration_absolute": "vor %s",
      "duration_relative": "nach %s",
    },
    "fr": {
      "title": "Durations",
      "label_field_hint": "Label",
      "add_button_tooltip": "Ajouter",
      "remove_button_tooltip": "Effacer",
      "export_menu_item": "Exporter...",
      "undo_label": "Annuler",
      "event_added": "Evénement enregistré.",
      "event_updated": "Evénement mis à jour.",
      "event_removed": "Evénement effacé.",
      "bucket_removed": "Série effacé.",
      "duration_never": "jamais",
      "duration_now": "maintenant",
      "duration_future": "pas encore",
      "duration_instantly": "immédiatement",
      "duration_one_week": "1 semaine",
      "duration_one_day": "1 jour",
      "duration_one_hour": "1 heure",
      "duration_one_minute": "une minute",
      "duration_weeks": "%d semaines",
      "duration_days": "%d jours",
      "duration_hours": "%d heures",
      "duration_minutes": "%d minutes",
      "duration_absolute": "il y a %s",
      "duration_relative": "après %s",
    },
  }[_locale.languageCode][key];

  String get title => message("title");
  String get labelFieldHint => message("label_field_hint");
  String get addButtonTooltip => message("add_button_tooltip");
  String get removeButtonTooltip => message("remove_button_tooltip");
  String get exportMenuItem => message("export_menu_item");
  String get undoLabel => message("undo_label");

  String formatDuration(Duration d, { bool relative = false }) {
    if (d == null) {
      checkArgument(!relative, message: "can't format missing durations relatively");
      return message("duration_never");
    }
    if (d.isNegative) {
      checkArgument(!relative, message: "can't format negative durations relatively");
      return message("duration_future");
    }
    if (d.inSeconds < 60) {
      return message(relative ? "duration_instantly" : "duration_now");
    }
    return sprintf(message(relative ? "duration_relative" : "duration_absolute"), [_formatDuration(d)]);
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 14) {
      return sprintf(message("duration_weeks"), [d.inDays ~/ 7]);
    }
    if (d.inDays >= 7) {
      return message("duration_one_week");
    }
    if (d.inDays > 1) {
      return sprintf(message("duration_days"), [d.inDays]);
    }
    if (d.inDays == 1) {
      return message("duration_one_day");
    }
    if (d.inHours > 1) {
      return sprintf(message("duration_hours"), [d.inHours]);
    }
    if (d.inHours == 1) {
      return message("duration_one_hour");
    }
    if (d.inMinutes > 1) {
      return sprintf(message("duration_minutes"), [d.inMinutes]);
    }
    if (d.inMinutes == 1) {
      return message("duration_one_minute");
    }
    return "";
  }

  String formatShortDate(DateTime date) => DateFormat.yMd(_locale.toString()).format(date);
}

class CustomLocalizationsDelegate extends LocalizationsDelegate<CustomLocalizations> {

  const CustomLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ["en", "de", "fr"].contains(locale.languageCode);

  @override
  Future<CustomLocalizations> load(Locale locale) => SynchronousFuture<CustomLocalizations>(CustomLocalizations(locale));

  @override
  bool shouldReload(CustomLocalizationsDelegate old) => false;
}
