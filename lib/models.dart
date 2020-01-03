import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:more/collection.dart';
import 'package:quiver/iterables.dart' as iterables;
import 'package:sprintf/sprintf.dart';
import 'package:uuid/uuid.dart';

@immutable
class Bucket extends Equatable {

  static final _uuid = Uuid().v4;

  final String id;
  final String label;
  final List<Event> events;

  Bucket.generate(String label) : this(_uuid(), label, const []);

  Bucket(this.id, this.label, Iterable<Event> events) : events = List.unmodifiable(events);

  OffsetDateTime get latest => events.isNotEmpty ? events.last.timestamp : null;

  @override
  List<Object> get props => [id, label, latest, size()];

  int size() => events.length;

  Bucket withEvent(Event event) {
    return Bucket(id, label, _modifyEvents((events) {
      events.removeWhere((e) => e.id == event.id);
      events.add(event);
    }));
  }

  Bucket withoutEvent(String eventId) {
    return Bucket(id, label, _modifyEvents((events) {
      events.removeWhere((event) => event.id == eventId);
    }));
  }

  List<Event> _modifyEvents(void apply(List<Event> events)) {
    var modifiable = List.of(events);
    apply(modifiable);
    modifiable.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return modifiable;
  }

  Histogram histogram() {
    var durations = <Duration>[];
    Event last;
    for (var event in events) {
      if (last != null) {
        durations.add(event.timestamp.utc.difference(last.timestamp.utc));
      }
      last = event;
    }
    return Histogram.from(durations);
  }

  String toString() => "{id: $id, label: $label, events: $events}";
}

@immutable
class Event extends Equatable {

  static final _uuid = Uuid().v4;

  final String id;
  final OffsetDateTime timestamp;

  Event(this.id, this.timestamp);

  Event.generate(OffsetDateTime timestamp) :
    this(_uuid(), timestamp);

  @override
  List<Object> get props => [id, timestamp];

  @override
  String toString() => "{id: $id, timestamp: $timestamp}";
}

@immutable
class OffsetDateTime extends Equatable implements Comparable<OffsetDateTime> {

  static final OffsetDateTime earliest = OffsetDateTime._(DateTime.fromMillisecondsSinceEpoch(0).toUtc(), Duration());

  final DateTime _utc;
  final Duration _offset;

  OffsetDateTime._(this._utc, this._offset);

  OffsetDateTime.now() : this(DateTime.now());

  OffsetDateTime(DateTime time) : _utc = time.toUtc(), _offset = time.timeZoneOffset;

  OffsetDateTime.parse(String s) : this._(DateTime.parse(s), _parseOffset(s));

  static final RegExp _offsetPattern = RegExp(r"([+\-])?(\d{2}):?(\d{2})$");

  static Duration _parseOffset(String s) {
    var hours = 0;
    var minutes = 0;
    var m = _offsetPattern.firstMatch(s);
    if (m != null) {
      var sign = m.group(1) == "-" ? -1 : 1;
      hours = sign * int.parse(m.group(2));
      minutes = sign * int.parse(m.group(3));
    }
    return Duration(hours: hours, minutes: minutes);
  }

  DateTime get utc => _utc;
  Duration get offset => _offset;
  DateTime get local => DateTime.fromMicrosecondsSinceEpoch(_utc.microsecondsSinceEpoch);
  List<Object> get props => [utc, offset];

  @override
  int compareTo(OffsetDateTime other) => _utc.compareTo(other._utc);

  @override
  String toString() => sprintf("%s%+03d:%02d", [
    _utc.add(_offset).toIso8601String().replaceAll("Z", ""),
    _offset.inHours,
    _offset.inMinutes.abs() % 60
  ]);
}

class Histogram extends Equatable {

  final List<Bin> bins;

  Histogram(this.bins);

  static Histogram from(Iterable<Duration> durations, { int maxBins = 5 }) {
    if (durations.isEmpty) {
      return Histogram(const []);
    }
    var days = durations.map((d) => d.inDays).toList();
    var binExtent = iterables.extent(days);
    var binSpan = binExtent.max - binExtent.min + 1;
    var binOffset = binExtent.min;
    var binSize = (binSpan / maxBins).ceil();
    var binCount = (binSpan / binSize).ceil();
    var binValues = Multiset.from(days.map((day) => (day - binOffset) ~/ binSize));
    var bins = List.generate(binCount, (i) => Bin(binOffset + i * binSize, binOffset + (i + 1) * binSize - 1, binValues[i]));
    return Histogram(bins);
  }

  @override
  List<Object> get props => [bins];

  @override
  String toString() => bins.toString();
}

class Bin extends Equatable {

  final int min, max;
  final int count;

  Bin(this.min, this.max, this.count);

  String get label => max > min ? "$min–${max}d" : "${min}d";

  @override
  List<Object> get props => [min, max, count];

  @override
  String toString() => "$label:$count";
}
