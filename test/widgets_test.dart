import 'package:durations/models.dart';
import 'package:durations/states.dart';
import 'package:durations/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redurx/flutter_redurx.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  CapturingMiddleware<AppState> actions;

  setUp(() {
    actions = CapturingMiddleware<AppState>();
  });

  Future<void> pumpState(WidgetTester tester, AppState initialState, [ Widget home = const BucketListPage() ]) async {
    var store = Store(initialState);
    store.add(UndoMiddleware());
    store.add(actions);
    await tester.pumpWidget(Provider(store: store, child: DurationsApp(home: home)));
    await tester.pump();
  }

  testWidgets("about dialog", (tester) async {

    const MethodChannel("plugins.flutter.io/package_info").setMockMethodCallHandler((call) async {
      if (call.method == "getAll") {
        return <String, dynamic>{
          "appName": "Foo",
          "version": "1.2.3",
        };
      }
      return null;
    });

    await pumpState(tester, AppState.from([]));

    await tester.tap(find.byKey(BucketListPage.menuKey));
    await tester.pumpAndSettle();

    await tester.tap(find.text("About..."));
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsOneWidget);
    expect(find.text("Foo"), findsOneWidget);
    expect(find.text("1.2.3"), findsOneWidget);

    await tester.tap(find.text("CLOSE"));
    await tester.pumpAndSettle();
    expect(find.byType(AboutDialog), findsNothing);
  });

  testWidgets("list buckets", (tester) async {

    var foo = Bucket.generate("foo");
    var bar = Bucket.generate("bar").withEvent(Event.generate(OffsetDateTime.now()));
    await pumpState(tester, AppState.from([foo, bar]));

    var findFoo = find.byKey(Key(foo.id));
    expect(findFoo, findsOneWidget);
    expect(find.descendant(of: findFoo, matching: find.text(foo.label)), findsOneWidget);
    expect(find.descendant(of: findFoo, matching: find.text("never")), findsOneWidget);
    expect(find.descendant(of: findFoo, matching: find.text("1")), findsNothing);

    var findBar = find.byKey(Key(bar.id));
    expect(findBar, findsOneWidget);
    expect(find.descendant(of: findBar, matching: find.text(bar.label)), findsOneWidget);
    expect(find.descendant(of: findBar, matching: find.text("just now")), findsOneWidget);
    expect(find.descendant(of: findBar, matching: find.text("1")), findsOneWidget);
  });

  testWidgets("add a bucket", (tester) async {

    await pumpState(tester, AppState.from([]));
    expect(find.byType(BucketTile), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.enterText(find.byKey(BucketDialogState.addBucketDialogLabelFieldKey), "foo");
    await tester.tap(find.byKey(BucketDialogState.addBucketDialogOkButtonKey));
    await tester.pump();

    expect(actions.count(), 1);
    expect(actions.get<Object>(0).runtimeType, StoreBucket);
    expect(actions.get<StoreBucket>(0).bucket.label, "foo");

    expect(find.byType(BucketTile), findsOneWidget);
    expect(find.byKey(Key(actions.get<StoreBucket>(0).bucket.id)), findsOneWidget);
  });

  testWidgets("add an instant event", (tester) async {

    var bucket = Bucket.generate("foo");
    await pumpState(tester, AppState.from([bucket]));
    expect(find.descendant(of: find.byKey(Key(bucket.id)), matching: find.text("1")), findsNothing);

    await tester.longPress(find.byKey(Key(bucket.id)));
    await tester.pump();

    expect(actions.count(), 1);
    expect(actions.get<Object>(0).runtimeType, StoreEvent);
    expect(actions.get<StoreEvent>(0).bucketId, bucket.id);
    expect(actions.get<StoreEvent>(0).event, isNotNull);

    expect(find.descendant(of: find.byKey(Key(bucket.id)), matching: find.text("1")), findsOneWidget);
    expect(find.byKey(UndoMiddleware.undoActionKey), findsOneWidget);
  });

  testWidgets("open a bucket", (tester) async {

    var event = Event.generate(OffsetDateTime.earliest);
    var bucket = Bucket.generate("foo").withEvent(event);
    await pumpState(tester, AppState.from([bucket]));

    await tester.tap(find.byKey(Key(bucket.id)));
    await tester.pumpAndSettle();

    expect(find.byType(BucketPage), findsOneWidget);
    expect(find.byType(BucketListPage), findsNothing);
    expect(find.byKey(Key(event.id)), findsOneWidget);
  });

  testWidgets("add an event", (tester) async {

    var bucket = Bucket.generate("foo");
    await pumpState(tester, AppState.from([bucket]), BucketPage(bucket));
    expect(find.byType(EventTile), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    await tester.tap(find.text("OK")); // date
    await tester.pump();
    await tester.tap(find.text("OK")); // time
    await tester.pump();

    expect(actions.count(), 1);
    expect(actions.get<Object>(0).runtimeType, StoreEvent);
    expect(actions.get<StoreEvent>(0).bucketId, bucket.id);
    expect(actions.get<StoreEvent>(0).event, isNotNull);

    expect(find.byType(EventTile), findsOneWidget);
    expect(find.byKey(Key(actions.get<StoreEvent>(0).event.id)), findsOneWidget);
    expect(find.byKey(UndoMiddleware.undoActionKey), findsOneWidget);
  });

  testWidgets("edit an event", (tester) async {

    var event = Event.generate(OffsetDateTime.earliest);
    var bucket = Bucket.generate("foo").withEvent(event);
    await pumpState(tester, AppState.from([bucket]), BucketPage(bucket));

    await tester.tap(find.byKey(Key(event.id)));
    await tester.pump();
    await tester.tap(find.text("OK")); // date
    await tester.pump();
    await tester.tap(find.text("OK")); // time
    await tester.pump();

    expect(actions.count(), 1);
    expect(actions.get<Object>(0).runtimeType, UpdateEvent);
    expect(actions.get<UpdateEvent>(0).bucketId, bucket.id);
    expect(actions.get<UpdateEvent>(0).from, event);
    expect(actions.get<UpdateEvent>(0).to.id, event.id);
    expect(actions.get<UpdateEvent>(0).to.timestamp, isNot(event.timestamp));

    expect(find.byType(EventTile), findsOneWidget);
    expect(find.byKey(UndoMiddleware.undoActionKey), findsOneWidget);
  });

  testWidgets("remove an event", (tester) async {

    var event = Event.generate(OffsetDateTime.earliest);
    var bucket = Bucket.generate("foo").withEvent(event);
    await pumpState(tester, AppState.from([bucket]), BucketPage(bucket));
    expect(find.byType(EventTile), findsOneWidget);

    await tester.drag(find.byType(EventTile), Offset(500.0, 0.0));
    await tester.pumpAndSettle();

    expect(actions.count(), 1);
    expect(actions.get<Object>(0).runtimeType, RemoveEvent);
    expect(actions.get<RemoveEvent>(0).bucketId, bucket.id);
    expect(actions.get<RemoveEvent>(0).event, event);

    expect(find.byType(EventTile), findsNothing);
    expect(find.byKey(UndoMiddleware.undoActionKey), findsOneWidget);
  });

  testWidgets("remove a bucket", (tester) async {

    var bucket = Bucket.generate("foo");
    await pumpState(tester, AppState.from([bucket]));

    await tester.tap(find.byKey(Key(bucket.id)));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete));
    await tester.pump(Duration(seconds: 1));

    expect(actions.count(), 1);
    expect(actions.get<Object>(0).runtimeType, RemoveBucket);
    expect(actions.get<RemoveBucket>(0).bucket, bucket);

    expect(find.byType(BucketListPage), findsOneWidget);
    expect(find.byType(BucketTile), findsNothing);
    expect(find.byKey(UndoMiddleware.undoActionKey), findsOneWidget);
  });
}

class CapturingMiddleware<T> extends Middleware<T> {

  final _actions = <ActionType>[];

  @override
  T afterAction(Store<T> store, ActionType action, T state) {
    _actions.add(action);
    return state;
  }

  int count() => _actions.length;

  T get<T>(int i) => _actions[i] as T;
}
