import 'package:durations/persistence.dart';
import 'package:durations/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redurx/flutter_redurx.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:redurx/redurx.dart';

void main() async {
  var base = await getApplicationDocumentsDirectory();
  var manager = DatabaseManager(path.join(base.path, "durations.db"));
  var buckets = BucketRepository(manager);
  var events = EventRepository(manager);
  var persistence = PersistenceMiddleware(buckets, events);
  var store = Store(await persistence.loadState());
  store.add(persistence);
  store.add(UndoMiddleware());
  runApp(Provider(store: store, child: DurationsApp()));
}
