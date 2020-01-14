import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_redurx/flutter_redurx.dart' as rx;
import 'package:meta/meta.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

import 'models.dart';
import 'states.dart';

class DatabaseManager {

  final String _path;
  Database _database;

  DatabaseManager(this._path);

  Future<Database> get database async {
    if (_database == null) {
      _database = await databaseFactoryIo.openDatabase(_path, version: 1);
    }
    return _database;
  }

  void close() {
    _database?.close();
  }

  void delete() {
    if (_database != null) {
      databaseFactoryIo.deleteDatabase(_database.path);
    }
  }
}

@immutable
class EventEntity extends Equatable {

  final String id;
  final String bucketId;
  final OffsetDateTime timestamp;

  EventEntity(this.id, this.bucketId, this.timestamp);

  EventEntity.fromMap(Map<String, dynamic> record) :
    this(record["id"] as String, record["bucket_id"] as String, OffsetDateTime.parse(record["timestamp"] as String));

  @override
  List<Object> get props => [id, bucketId, timestamp];

  Map<String, String> toMap() => {
    "id": id,
    "bucket_id": bucketId,
    "timestamp": timestamp.toString()
  };

  @override
  String toString() => toMap().toString();
}

class EventRepository {

  final _store = stringMapStoreFactory.store("events");
  final DatabaseManager _manager;

  EventRepository(this._manager);

  Future<void> store(EventEntity event) async {
    await _store.record(event.id).put(await _manager.database, event.toMap());
  }

  Future<void> remove(String id) async {
    await _store.record(id).delete(await _manager.database);
  }

  Future<void> removeAll(String bucketId) async {
    await _store.delete(await _manager.database, finder: Finder(
      filter: Filter.equals("bucket_id", bucketId)
    ));
  }

  Future<EventEntity> find(String id) async {
    var record = await _store.record(id).get(await _manager.database);
    return record != null ? EventEntity.fromMap(record) : null;
  }

  Future<List<EventEntity>> findAll(String bucketId) async {
    var records = await _store.find(await _manager.database, finder: Finder(
      filter: Filter.equals("bucket_id", bucketId),
      sortOrders: [SortOrder("timestamp")]
    ));
    return records.map((record) => EventEntity.fromMap(record.value)).toList();
  }
}

@immutable
class BucketEntity extends Equatable {

  final String id;
  final String label;

  BucketEntity(this.id, this.label);

  BucketEntity.fromMap(Map<String, dynamic> record) :
    this(record["id"] as String, record["label"] as String);

  @override
  List<Object> get props => [id, label];

  Map<String, String> toMap() => {
    "id": id,
    "label": label
  };

  @override
  String toString() => toMap().toString();
}

class BucketRepository {

  final _store = stringMapStoreFactory.store("buckets");
  final DatabaseManager _manager;

  BucketRepository(this._manager);

  Future<void> store(BucketEntity bucket) async {
    await _store.record(bucket.id).put(await _manager.database, bucket.toMap());
  }

  Future<void> remove(String id) async {
    await _store.record(id).delete(await _manager.database);
  }

  Future<BucketEntity> find(String id) async {
    var record = await _store.record(id).get(await _manager.database);
    return record != null ? BucketEntity.fromMap(record) : null;
  }

  Future<List<BucketEntity>> findAll() async {
    var finder = Finder(
        sortOrders: [SortOrder("label")]
    );
    var records = await _store.find(await _manager.database, finder: finder);
    return records.map((record) => BucketEntity.fromMap(record.value)).toList();
  }
}

class PersistenceMiddleware extends rx.Middleware<AppState> {

  final BucketRepository _buckets;
  final EventRepository _events;

  PersistenceMiddleware(this._buckets, this._events);

  Future<AppState> loadState() async {
    var buckets = <Bucket>[];
    for (var bucket in await _buckets.findAll()) {
      var events = await _events.findAll(bucket.id);
      buckets.add(Bucket(bucket.id, bucket.label, events.map((event) => Event(event.id, event.timestamp))));
    }
    return AppState.from(buckets);
  }

  @override
  AppState afterAction(rx.Store<AppState> store, rx.ActionType action, AppState state) {
    if (action is StoreBucket) {
      _buckets.store(BucketEntity(action.bucket.id, action.bucket.label));
      for (var event in action.bucket.events) {
        _events.store(EventEntity(event.id, action.bucket.id, event.timestamp));
      }
    } else if (action is RemoveBucket) {
      _buckets.remove(action.bucket.id);
      _events.removeAll(action.bucket.id);
    } else if (action is StoreEvent) {
      _events.store(EventEntity(action.event.id, action.bucketId, action.event.timestamp));
    } else if (action is RemoveEvent) {
      _events.remove(action.event.id);
    }
    return state;
  }
}
