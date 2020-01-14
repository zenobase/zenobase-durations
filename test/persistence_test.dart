import 'package:durations/models.dart';
import 'package:durations/persistence.dart';
import 'package:durations/states.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import "package:test/test.dart";
import 'package:uuid/uuid.dart';

void main() {

  group("repositories", () {

    DatabaseManager manager;
    var uuid = Uuid().v4;

    setUp(() async {
      manager = DatabaseManager(path.join("build", "test.db"));
    });

    test("create, read, update, and delete an event", () async {

      var repository = EventRepository(manager);
      var event = EventEntity(uuid(), uuid(), OffsetDateTime.earliest);
      expect(await repository.find(event.id), isNull, reason: "find unstored event");

      await repository.store(event);
      var actual = await repository.find(event.id);
      expect(actual, equals(event), reason: "find stored event");

      event = EventEntity(event.id, event.bucketId, OffsetDateTime(DateTime.now()));
      await repository.store(event);
      var updated = await repository.find(event.id);
      expect(updated, equals(event), reason: "find updated event");

      await repository.remove(event.id);
      expect(await repository.find(event.id), isNull, reason: "find removed event");
    });

    test("find events", () async {

      var repository = EventRepository(manager);
      var first = EventEntity(uuid(), uuid(), OffsetDateTime.earliest);
      var second = EventEntity(uuid(), first.bucketId, OffsetDateTime.now());
      var other = EventEntity(uuid(), uuid(), first.timestamp);

      await Future.forEach<EventEntity>([first, second, other], (event) => repository.store(event));
      expect(await repository.findAll(first.bucketId), equals([first, second]));

      await repository.removeAll(first.bucketId);
      expect(await repository.findAll(first.bucketId), isEmpty);
      expect(await repository.findAll(other.bucketId), equals([other]));
    });

    test("create, read, update, and delete a bucket", () async {

      var repository = BucketRepository(manager);
      var bucket = BucketEntity(uuid(), "test");
      expect(await repository.find(bucket.id), isNull, reason: "find unstored bucket");

      await repository.store(bucket);
      var actual = await repository.find(bucket.id);
      expect(actual, equals(bucket), reason: "find stored bucket");

      bucket = BucketEntity(bucket.id, bucket.label.toUpperCase());
      await repository.store(bucket);
      var updated = await repository.find(bucket.id);
      expect(updated, equals(bucket), reason: "find updated bucket");

      await repository.remove(bucket.id);
      expect(await repository.find(bucket.id), isNull, reason: "find removed bucket");
    });

    test("find buckets", () async {

      var repository = BucketRepository(manager);
      var foo = BucketEntity(uuid(), "foo");
      var bar = BucketEntity(uuid(), "bar");

      await Future.forEach<BucketEntity>([foo, bar], (bucket) => repository.store(bucket));
      expect(await repository.findAll(), equals([bar, foo]));
    });

    tearDown(() {
      manager?.close();
      manager?.delete();
    });
  });

  group("PersistenceMiddleware", () {

    var id = Uuid().v4();
    EventRepository events;
    BucketRepository buckets;
    PersistenceMiddleware persistence;

    setUp(() {
      events = MockEventRepository();
      buckets = MockBucketRepository();
      persistence = PersistenceMiddleware(buckets, events);
    });

    test("store a bucket", () {
      var event = Event.generate(OffsetDateTime.earliest);
      var bucket = Bucket.generate("test").withEvent(event);
      persistence.afterAction(null, StoreBucket(bucket), null);
      verify(buckets.store(BucketEntity(bucket.id, bucket.label)));
      verify(events.store(EventEntity(event.id, bucket.id, event.timestamp)));
    });

    test("remove a bucket", () {
      var bucket = Bucket.generate("test");
      persistence.afterAction(null, RemoveBucket(bucket), null);
      verify(buckets.remove(bucket.id));
      verify(events.removeAll(bucket.id));
    });

    test("store an event", () {
      var event = Event.generate(OffsetDateTime.earliest);
      persistence.afterAction(null, StoreEvent(id, event), null);
      verify(events.store(EventEntity(event.id, id, event.timestamp)));
    });

    test("remove an event", () {
      var event = Event.generate(OffsetDateTime.earliest);
      persistence.afterAction(null, RemoveEvent(id, event), null);
      verify(events.remove(event.id));
    });

    test("load state", () async {
      var event = Event.generate(OffsetDateTime.earliest);
      var bucket = Bucket.generate("test").withEvent(event);
      when(buckets.findAll()).thenAnswer((_) => Future.value([BucketEntity(bucket.id, bucket.label)]));
      when(events.findAll(bucket.id)).thenAnswer((_) => Future.value([EventEntity(event.id, bucket.id, event.timestamp)]));
      var state = await persistence.loadState();
      expect(state.findBuckets(), equals([bucket]));
      verify(buckets.findAll());
      verify(events.findAll(bucket.id));
    });

    tearDown(() {
      verifyNoMoreInteractions(buckets);
      verifyNoMoreInteractions(events);
    });
  });
}

class MockEventRepository extends Mock implements EventRepository {}

class MockBucketRepository extends Mock implements BucketRepository {}
