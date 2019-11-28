import 'package:durations/models.dart';
import 'package:meta/meta.dart';
import 'package:quiver/check.dart';
import 'package:redurx/redurx.dart';

@immutable
class AppState {

  final Map<String, Bucket> _buckets;

  AppState._(Map<String, Bucket> buckets) : _buckets = Map.unmodifiable(buckets);

  AppState.from(Iterable<Bucket> buckets) : this._(Map.fromIterable(buckets, key: (bucket) => bucket.id));

  AppState storeBucket(Bucket bucket) {
    return _modify((buckets) => buckets[bucket.id] = bucket);
  }

  AppState removeBucket(String id) {
    return _modify((buckets) => buckets.remove(id));
  }

  AppState storeEvent(String bucketId, Event event) {
    var bucket = checkNotNull(_buckets[bucketId]);
    return _modify((buckets) => buckets[bucket.id] = bucket.withEvent(event));
  }

  AppState removeEvent(String bucketId, Event event) {
    var bucket = checkNotNull(_buckets[bucketId]);
    return _modify((buckets) => buckets[bucket.id] = bucket.withoutEvent(event.id));
  }

  AppState _modify(void apply(Map<String, Bucket> buckets)) {
    var buckets = Map.of(_buckets);
    apply(buckets);
    return AppState._(buckets);
  }

  Bucket findBucket(String id) => _buckets[id];

  List<Bucket> findBuckets() {
    var buckets = _buckets.values.toList();
    buckets.sort((a, b) => (b.latest ?? OffsetDateTime.earliest).compareTo(a.latest ?? OffsetDateTime.earliest));
    return buckets;
  }
}

abstract class UndoableAction<T> extends Action<T> {

  final String message;

  UndoableAction(this.message);

  Action<T> undo();
}

@immutable
class StoreBucket extends Action<AppState> {

  final Bucket bucket;

  StoreBucket(this.bucket);

  @override
  AppState reduce(AppState state) {
    return state.storeBucket(bucket);
  }
}

@immutable
class RemoveBucket extends UndoableAction<AppState> {

  final Bucket bucket;

  RemoveBucket(this.bucket) : super("bucket_removed");

  @override
  AppState reduce(AppState state) {
    return state.removeBucket(bucket.id);
  }

  @override
  StoreBucket undo() {
    return StoreBucket(bucket);
  }
}

@immutable
class StoreEvent extends UndoableAction<AppState> {

  final String bucketId;
  final Event event;

  StoreEvent(this.bucketId, this.event) : super("event_added");

  @override
  AppState reduce(AppState state) {
    return state.storeEvent(bucketId, event);
  }

  RemoveEvent undo() {
    return RemoveEvent(bucketId, event);
  }
}

@immutable
class UpdateEvent extends UndoableAction<AppState> {

  final String bucketId;
  final Event from, to;

  UpdateEvent(this.bucketId, this.from, this.to) : super("event_updated");

  @override
  AppState reduce(AppState state) {
    return state.storeEvent(bucketId, to);
  }

  UpdateEvent undo() {
    return UpdateEvent(bucketId, to, from);
  }
}

@immutable
class RemoveEvent extends UndoableAction<AppState> {

  final String bucketId;
  final Event event;

  RemoveEvent(this.bucketId, this.event) : super("event_removed");

  @override
  AppState reduce(AppState state) {
    return state.removeEvent(bucketId, event);
  }

  @override
  StoreEvent undo() {
    return StoreEvent(bucketId, event);
  }
}

