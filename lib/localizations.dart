import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quiver/check.dart';
import 'package:sprintf/sprintf.dart';

import 'models.dart';

class CustomLocalizations {

  final Locale _locale;

  CustomLocalizations(this._locale);

  static CustomLocalizations of(BuildContext context) {
    return Localizations.of<CustomLocalizations>(context, CustomLocalizations);
  }

  String message(MessageKey key) => const {
    "en": {
      MessageKey.title: "Durations",
      MessageKey.label: "Label",
      MessageKey.add: "Add",
      MessageKey.remove: "Remove",
      MessageKey.export: "Export...",
      MessageKey.undo: "Undo",
      MessageKey.and: "and",
      MessageKey.eventAdded: "Logged an event.",
      MessageKey.eventUpdated: "Updated an event.",
      MessageKey.eventRemoved: "Removed an event.",
      MessageKey.bucketRemoved: "Removed a series.",
      MessageKey.durationNever: "never",
      MessageKey.durationNow: "just now",
      MessageKey.durationFuture: "not yet",
      MessageKey.durationInstantly: "immediately",
      MessageKey.durationOneWeek: "1 week",
      MessageKey.durationOneDay: "1 day",
      MessageKey.durationOneHour: "1 hour",
      MessageKey.durationOneMinute: "1 minute",
      MessageKey.durationWeeks: "%d weeks",
      MessageKey.durationDays: "%d days",
      MessageKey.durationHours: "%d hours",
      MessageKey.durationMinutes: "%d minutes",
      MessageKey.durationAbsolute: "%s ago",
      MessageKey.durationRelative: "after %s",
    },
    "de": {
      MessageKey.title: "Durations",
      MessageKey.label: "Label",
      MessageKey.add: "Hinzufügen",
      MessageKey.remove: "Löschen",
      MessageKey.export: "Exportieren...",
      MessageKey.undo: "Rückgängig machen",
      MessageKey.and: "und",
      MessageKey.eventAdded: "Ein Ereignis wurde hinzugefügt.",
      MessageKey.eventUpdated: "Ein Ereignis wurde aktualisiert.",
      MessageKey.eventRemoved: "Ein Ereignis wurde gelöscht.",
      MessageKey.bucketRemoved: "Eine Serie wurde gelöscht.",
      MessageKey.durationNever: "noch nie",
      MessageKey.durationNow: "jetzt",
      MessageKey.durationInstantly: "sofort",
      MessageKey.durationFuture: "noch nicht",
      MessageKey.durationOneWeek: "1 Woche",
      MessageKey.durationOneDay: "1 Tag",
      MessageKey.durationOneHour: "1 Stunde",
      MessageKey.durationOneMinute: "1 Minute",
      MessageKey.durationWeeks: "%d Wochen",
      MessageKey.durationDays: "%d Tagen",
      MessageKey.durationHours: "%d Stunden",
      MessageKey.durationMinutes: "%d Minuten",
      MessageKey.durationAbsolute: "vor %s",
      MessageKey.durationRelative: "nach %s",
    },
    "fr": {
      MessageKey.title: "Durations",
      MessageKey.label: "Label",
      MessageKey.add: "Ajouter",
      MessageKey.remove: "Effacer",
      MessageKey.export: "Exporter...",
      MessageKey.undo: "Annuler",
      MessageKey.and: "et",
      MessageKey.eventAdded: "Evénement enregistré.",
      MessageKey.eventUpdated: "Evénement mis à jour.",
      MessageKey.eventRemoved: "Evénement effacé.",
      MessageKey.bucketRemoved: "Série effacée.",
      MessageKey.durationNever: "jamais",
      MessageKey.durationNow: "maintenant",
      MessageKey.durationFuture: "pas encore",
      MessageKey.durationInstantly: "immédiatement",
      MessageKey.durationOneWeek: "1 semaine",
      MessageKey.durationOneDay: "1 jour",
      MessageKey.durationOneHour: "1 heure",
      MessageKey.durationOneMinute: "une minute",
      MessageKey.durationWeeks: "%d semaines",
      MessageKey.durationDays: "%d jours",
      MessageKey.durationHours: "%d heures",
      MessageKey.durationMinutes: "%d minutes",
      MessageKey.durationAbsolute: "il y a %s",
      MessageKey.durationRelative: "après %s",
    },
  }[_locale.languageCode][key];

  String formatDuration(Duration d, { bool relative = false }) {
    if (d == null) {
      checkArgument(!relative, message: "can't format missing durations relatively");
      return message(MessageKey.durationNever);
    }
    if (d.isNegative) {
      checkArgument(!relative, message: "can't format negative durations relatively");
      return message(MessageKey.durationFuture);
    }
    if (d.inSeconds < 60) {
      return message(relative ? MessageKey.durationInstantly : MessageKey.durationNow);
    }
    return sprintf(message(relative ? MessageKey.durationRelative : MessageKey.durationAbsolute), [
      d.decompose().map(_formatDuration).join(" ${message(MessageKey.and)} ")
    ]);
  }

  String _formatDuration(Duration d) {
    if (d.inWeeks > 1) {
      return sprintf(message(MessageKey.durationWeeks), [d.inWeeks]);
    }
    if (d.inWeeks == 1) {
      return message(MessageKey.durationOneWeek);
    }
    if (d.inDays > 1) {
      return sprintf(message(MessageKey.durationDays), [d.inDays]);
    }
    if (d.inDays == 1) {
      return message(MessageKey.durationOneDay);
    }
    if (d.inHours > 1) {
      return sprintf(message(MessageKey.durationHours), [d.inHours]);
    }
    if (d.inHours == 1) {
      return message(MessageKey.durationOneHour);
    }
    if (d.inMinutes > 1) {
      return sprintf(message(MessageKey.durationMinutes), [d.inMinutes]);
    }
    if (d.inMinutes == 1) {
      return message(MessageKey.durationOneMinute);
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

enum MessageKey {
  title,
  label,
  add,
  remove,
  export,
  undo,
  and,
  eventAdded,
  eventUpdated,
  eventRemoved,
  bucketRemoved,
  durationNever,
  durationNow,
  durationFuture,
  durationInstantly,
  durationOneWeek,
  durationOneDay,
  durationOneHour,
  durationOneMinute,
  durationWeeks,
  durationDays,
  durationHours,
  durationMinutes,
  durationAbsolute,
  durationRelative,
}
