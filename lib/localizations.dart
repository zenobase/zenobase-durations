import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      "duration_future": "sometime",
      "duration_one_week_past": "1 week ago",
      "duration_one_day_past": "1 day ago",
      "duration_one_hour_past": "1 hour ago",
      "duration_one_minute_past": "1 minute ago",
      "duration_weeks_past": "%d weeks ago",
      "duration_days_past": "%d days ago",
      "duration_hours_past": "%d hours ago",
      "duration_minutes_past": "%d minutes ago",
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
      "duration_future": "irgendwann",
      "duration_one_week_past": "vor einer Woche",
      "duration_one_day_past": "vor 1 Tag",
      "duration_one_hour_past": "vor einer Stunde",
      "duration_one_minute_past": "vor einer Minute",
      "duration_weeks_past": "vor %d Wochen",
      "duration_days_past": "vor %d Tagen",
      "duration_hours_past": "vor %d Stunden",
      "duration_minutes_past": "vor %d Minuten",
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
      "duration_future": "un jour",
      "duration_one_week_past": "il y a une semaine",
      "duration_one_day_past": "il y a un jour",
      "duration_one_hour_past": "il y a une heure",
      "duration_one_minute_past": "il y a une minute",
      "duration_weeks_past": "il y a %d semaines",
      "duration_days_past": "il y a %d jours",
      "duration_hours_past": "il y a %d heurs",
      "duration_minutes_past": "il y a %d minutes",
    },
  }[_locale.languageCode][key];

  String get title => message("title");
  String get labelFieldHint => message("label_field_hint");
  String get addButtonTooltip => message("add_button_tooltip");
  String get removeButtonTooltip => message("remove_button_tooltip");
  String get exportMenuItem => message("export_menu_item");
  String get undoLabel => message("undo_label");

  String formatDuration(Duration d) {
    if (d == null) {
      return message("duration_never");
    }
    if (d.inDays >= 14) {
      return sprintf(message("duration_weeks_past"), [d.inDays ~/ 7]);
    }
    if (d.inDays >= 7) {
      return message("duration_one_week_past");
    }
    if (d.inDays > 1) {
      return sprintf(message("duration_days_past"), [d.inDays]);
    }
    if (d.inDays == 1) {
      return message("duration_one_day_past");
    }
    if (d.inHours > 1) {
      return sprintf(message("duration_hours_past"), [d.inHours]);
    }
    if (d.inHours == 1) {
      return message("duration_one_hour_past");
    }
    if (d.inMinutes > 1) {
      return sprintf(message("duration_minutes_past"), [d.inMinutes]);
    }
    if (d.inMinutes == 1) {
      return message("duration_one_minute_past");
    }
    if (d.inMinutes > -1) {
      return message("duration_now");
    }
    return message("duration_future");
  }
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
