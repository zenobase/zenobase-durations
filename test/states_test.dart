import 'package:durations/models.dart';
import 'package:durations/states.dart';
import "package:test/test.dart";

void main() {

  group("AppState", () {

    test("find buckets", () {
      var older = Bucket.generate("older").withEvent(Event.generate(OffsetDateTime.earliest));
      var newer = Bucket.generate("newer").withEvent(Event.generate(OffsetDateTime.now()));
      var state = AppState.from([older, newer]);
      expect(state.findBuckets(), [newer, older]);
    });

    test("store a bucket", () {
      var bucket = Bucket.generate("test");
      var action = StoreBucket(bucket);
      var state0 = AppState.from(const []);
      var state1 = action.reduce(state0);
      expect(state0.findBucket(bucket.id), isNull);
      expect(state1.findBucket(bucket.id), bucket);
    });

    test("remove a bucket", () {
      var bucket = Bucket.generate("test");
      var action = RemoveBucket(bucket);
      var state0 = AppState.from([bucket]);
      var state1 = action.reduce(state0);
      expect(state0.findBucket(bucket.id), bucket);
      expect(state1.findBucket(bucket.id), isNull);
      expect(action.undo().bucket, bucket);
    });

    test("store an event", () {
      var bucket = Bucket.generate("test");
      var event = Event.generate(OffsetDateTime.earliest);
      var action = StoreEvent(bucket.id, event);
      var state0 = AppState.from([bucket]);
      var state1 = action.reduce(state0);
      expect(state0.findBucket(bucket.id).events, <Event>[]);
      expect(state1.findBucket(bucket.id).events, [event]);
      expect(action.undo().bucketId, bucket.id);
      expect(action.undo().event, event);
    });

    test("update an event", () {
      var from = Event.generate(OffsetDateTime.earliest);
      var to = Event(from.id, OffsetDateTime.now());
      var bucket = Bucket.generate("test").withEvent(from);
      var action = UpdateEvent(bucket.id, from, to);
      var state0 = AppState.from([bucket]);
      var state1 = action.reduce(state0);
      expect(state0.findBucket(bucket.id).events, [from]);
      expect(state1.findBucket(bucket.id).events, [to]);
      expect(action.undo().bucketId, bucket.id);
      expect(action.undo().from, to);
      expect(action.undo().to, from);
    });

    test("remove an event", () {
      var bucket = Bucket.generate("test");
      var event = Event.generate(OffsetDateTime.earliest);
      var action = RemoveEvent(bucket.id, event);
      var state0 = AppState.from([bucket.withEvent(event)]);
      var state1 = action.reduce(state0);
      expect(state0.findBucket(bucket.id).events, [event]);
      expect(state1.findBucket(bucket.id).events, <Event>[]);
      expect(action.undo().bucketId, bucket.id);
      expect(action.undo().event, event);
    });
  });
}
