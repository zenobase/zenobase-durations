import 'package:flutter/material.dart';
import 'package:flutter_redurx/flutter_redurx.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:redurx/redurx.dart';

import 'persistence.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
