import 'package:durations/models.dart';
import 'package:quiver/testing/equality.dart';
import "package:test/test.dart";

void main() {

  group("Bucket", () {

    test("add, update, and remove an event", () {

      final bucket = Bucket.generate("test");
      var event = Event.generate(OffsetDateTime.earliest);
      var updated = bucket.withEvent(event);

      expect(updated.id, equals(bucket.id), reason: "id for the updated bucket");
      expect(updated.label, equals(bucket.label), reason: "label for the updated bucket");
      expect(bucket.events, equals(<Event>[]), reason: "events for the original bucket");
      expect(updated.events, equals([event]), reason: "events for the updated bucket");

      event = Event(event.id, OffsetDateTime.now());
      updated = updated.withEvent(event);
      expect(updated.events, equals([event]), reason: "updated event");

      expect(updated.withoutEvent(event.id), equals(bucket), reason: "bucket after removing the event");
    });

    test("histogram", () {
      var now = DateTime.now();
      var bucket = Bucket.generate("foo")
          .withEvent(Event.generate(OffsetDateTime(now)))
          .withEvent(Event.generate(OffsetDateTime(now.add(Duration(days: 1)))));
      expect(bucket.histogram(), Histogram([Bin(1, 1, 1)]));
    });

    test("equality", () {
      final bucket = Bucket.generate("foo");
      expect({
        "same": [
          bucket,
          Bucket(bucket.id, bucket.label, bucket.events)
        ],
        "different name": [
          Bucket(bucket.id, "bar", bucket.events)
        ],
        "different events": [
          bucket.withEvent(Event.generate(OffsetDateTime.earliest)),
          bucket.withEvent(Event.generate(OffsetDateTime.earliest)) // equal event.id
        ]
      }, areEqualityGroups);
    });
  });

  group("Event", () {

    test("equality", () {
      final event = Event.generate(OffsetDateTime.earliest);
      expect({
        "same": [
          event,
          Event(event.id, event.timestamp)
        ],
        "different timestamp": [
          Event(event.id, OffsetDateTime.now())
        ]
      }, areEqualityGroups);
    });
  });

  group("OffsetDateTime", () {

    test("from local time", () {
      var local = DateTime.now();
      var t = OffsetDateTime(local);
      expect(t.utc, equals(local.toUtc()));
      expect(t.offset, equals(local.timeZoneOffset));
      expect(t.local, equals(local));
    });

    test("to local time", () {
      var s = "2019-07-31T12:34:56.789-05:30";
      var t = OffsetDateTime.parse(s);
      expect(t.local, equals(DateTime(2019, 7, 31, 12, 34, 56, 789).add(t.local.timeZoneOffset - t.offset)));
      expect(t.toString(), equals(s));
    });

    test("parse with negative offset", () {
      var s = "2019-07-31T12:34:56.789-05:30";
      var t = OffsetDateTime.parse(s);
      expect(t.utc, equals(DateTime.utc(2019, 7, 31, 18, 4, 56, 789)));
      expect(t.offset, equals(Duration(hours: -5, minutes: -30)));
      expect(t.toString(), equals(s));
    });

    test("parse with positive offset", () {
      var s = "2019-07-31T12:34:56.789+05:30";
      var t = OffsetDateTime.parse(s);
      expect(t.utc, equals(DateTime.utc(2019, 7, 31, 7, 4, 56, 789)));
      expect(t.offset, equals(Duration(hours: 5, minutes: 30)));
      expect(t.toString(), equals(s));
    });

    test("parse with zero offset", () {
      var s = "2019-07-31T12:34:56.789+00:00";
      var t = OffsetDateTime.parse(s);
      expect(t.utc, equals(DateTime.utc(2019, 7, 31, 12, 34, 56, 789)));
      expect(t.offset, equals(Duration(hours: 0, minutes: 0)));
      expect(t.toString(), equals(s));
    });

    test("equality", () {
      var now = DateTime.now();
      expect({
        "now": [OffsetDateTime(now), OffsetDateTime(now)],
        "earliest": [OffsetDateTime.earliest]
      }, areEqualityGroups);
    });
  });

  group("Histogram", () {

    test("empty", () {
      expect(Histogram.from([]), Histogram([]));
    });

    test("single value", () {
      expect(Histogram.from([
        Duration(days: 42),
      ]), Histogram([
        Bin(42, 42, 1)
      ]));
    });

    test("multiple values, single bin", () {
      expect(Histogram.from([
        Duration(days: 42),
        Duration(days: 42),
      ]), Histogram([
        Bin(42, 42, 2)
      ]));
    });

    test("multiple values, multiple bins", () {
      expect(Histogram.from([
        Duration(days: 4),
        Duration(days: 4),
        Duration(days: 5),
      ]), Histogram([
        Bin(4, 4, 2),
        Bin(5, 5, 1),
      ]));
    });

    test("bins spanning multiple values", () {
      expect(Histogram.from([
        Duration(days: 1),
        Duration(days: 2),
        Duration(days: 3),
        Duration(days: 4),
        Duration(days: 5),
        Duration(days: 6),
      ]), Histogram([
        Bin(1, 2, 2),
        Bin(3, 4, 2),
        Bin(5, 6, 2),
      ]));
    });
  });
}
