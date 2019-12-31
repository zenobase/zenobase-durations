import 'dart:async';

import 'package:durations/localizations.dart';
import 'package:durations/models.dart';
import 'package:durations/states.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redurx/flutter_redurx.dart';
import 'package:quiver/strings.dart';

class DurationsApp extends StatelessWidget {

  final Widget _home;

  DurationsApp({ Widget home = const BucketListPage() }) : _home = home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Durations",
      home: _home,
      theme: ThemeData(
        brightness:Brightness.light
      ),
      darkTheme: ThemeData(
        brightness:Brightness.dark
      ),
      localizationsDelegates: [
        const CustomLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale("en"),
        const Locale("de"),
        const Locale("fr"),
      ],
    );
  }
}

class BucketListPage extends StatelessWidget {

  const BucketListPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CustomLocalizations.of(context).title),
      ),
      body: ContextCapture(
        child: RefreshIndicator(
          onRefresh: () async => (context as Element).markNeedsBuild(),
          child: Connect<AppState, List<Bucket>>(
            convert: (state) => state.findBuckets(),
            where: (oldBuckets, newBuckets) => newBuckets != oldBuckets,
            builder: (List<Bucket> buckets) => ListView.separated(
              itemCount: buckets.length,
              itemBuilder: (context, i) => BucketTile(buckets[i]),
              separatorBuilder: (context, i) => Divider(),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => BucketDialog(),
        ),
        tooltip: CustomLocalizations.of(context).addButtonTooltip,
        child: Icon(Icons.add),
      ),
    );
  }
}

class BucketTile extends StatelessWidget {

  final Bucket _bucket;

  BucketTile(this._bucket);

  Duration _since() => _bucket.latest != null ? DateTime.now().difference(_bucket.latest.utc) : null;

  @override
  Widget build(BuildContext context) => ListTile(
    key: Key(_bucket.id),
    title: Text(_bucket.label),
    subtitle: Text(CustomLocalizations.of(context).formatDuration(_since())),
    trailing: _bucket.size() > 0 ? Chip(label: Text(_bucket.size().toString())) : null,
    onTap: () => Navigator.push(context, MaterialPageRoute<bool>(builder: (context) => BucketPage(_bucket))),
    onLongPress: () => Provider.dispatch<AppState>(context, StoreEvent(_bucket.id, Event.generate(OffsetDateTime.now()))),
  );
}

class BucketDialog extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => BucketDialogState();
}

class BucketDialogState extends State<BucketDialog> {

  static const addBucketDialogLabelFieldKey = Key("addBucketDialogLabelField");
  static const addBucketDialogOkButtonKey = Key("addBucketDialogOkButton");

  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    content: TextField(
      key: addBucketDialogLabelFieldKey,
      controller: _controller,
      decoration: InputDecoration(hintText: CustomLocalizations.of(context).labelFieldHint),
      autofocus: true,
    ),
    actions: <Widget>[
      SimpleDialogOption(
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        onPressed: () => Navigator.of(context).pop(),
      ),
      SimpleDialogOption(
        key: addBucketDialogOkButtonKey,
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
        onPressed: () {
          if (isNotBlank(_controller.text)) {
            Provider.dispatch<AppState>(context, StoreBucket(Bucket.generate(_controller.text)));
            Navigator.of(context).pop();
          }
        },
      ),
    ],
  );

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class BucketPage extends StatefulWidget {

  final Bucket _bucket;

  const BucketPage(this._bucket);

  @override
  BucketPageState createState() => BucketPageState();
}

class BucketPageState extends State<BucketPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget._bucket.label),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.delete),
              tooltip: CustomLocalizations.of(context).removeButtonTooltip,
              onPressed: () {
                Future.delayed(Duration(seconds: 1), () => Provider.dispatch<AppState>(ContextCapture.current(), RemoveBucket(widget._bucket)));
                Navigator.pop(context, true);
              },
            )
          ],
        ),
        body: ContextCapture(
          child: Connect<AppState, Bucket>(
            convert: (state) => state.findBucket(widget._bucket.id),
            where: (oldBucket, newBucket) => newBucket != oldBucket || newBucket.events != oldBucket.events,
            builder: (Bucket bucket) => ListView.separated(
              itemCount: bucket.size(),
              itemBuilder: (context, i) => EventTile(bucket, bucket.events[bucket.size() - 1 - i]),
              separatorBuilder: (context, i) => Divider(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var time = await _showDateTimePicker(context, DateTime.now());
            if (time != null) {
              Provider.dispatch<AppState>(context, StoreEvent(widget._bucket.id, Event.generate(OffsetDateTime(time))));
            }
          },
          tooltip: CustomLocalizations.of(context).addButtonTooltip,
          child: Icon(Icons.add),
        )
    );
  }
}

class EventTile extends StatelessWidget {

  final Bucket _bucket;
  final Event _event;

  EventTile(this._bucket, this._event);

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(_event.id),
    child: ListTile(
      title: Text(MaterialLocalizations.of(context).formatFullDate(_event.timestamp.local)),
      subtitle: Text(MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_event.timestamp.local))),
      onTap: () async {
        var time = await _showDateTimePicker(context, _event.timestamp.local);
        if (time != null) {
          Provider.dispatch<AppState>(context, UpdateEvent(_bucket.id, _event, Event(_event.id, OffsetDateTime(time))));
        }
      },
    ),
    onDismissed: (direction) {
      Provider.dispatch<AppState>(context, RemoveEvent(_bucket.id, _event));
    },
  );
}

Future<DateTime> _showDateTimePicker(BuildContext context, DateTime initial) async {
  var day = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: OffsetDateTime.earliest.local,
    lastDate: DateTime.now()
  );
  if (day == null) {
    return null;
  }
  var timeOfDay = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
  );
  if (timeOfDay == null) {
    return null;
  }
  return DateTime(day.year, day.month, day.day, timeOfDay.hour, timeOfDay.minute);
}

class ContextCapture extends StatefulWidget {

  static final _contexts = <BuildContext>[];

  final Widget _child;

  ContextCapture({ Widget child }) : _child = child;

  static BuildContext current() => _contexts.isNotEmpty ? _contexts.last : null;

  static void push(BuildContext context) => _contexts.add(context);

  static void pop() => _contexts.removeLast();

  @override
  State<StatefulWidget> createState() {
    return ContextCaptureState();
  }
}

class ContextCaptureState extends State<ContextCapture> {

  @override
  void initState() {
    ContextCapture.push(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget._child;
  }

  @override
  void dispose() {
    ContextCapture.pop();
    super.dispose();
  }
}

class UndoMiddleware extends Middleware<AppState> {

  static const undoActionKey = Key("undoAction");

  @override
  AppState afterAction(Store<AppState> store, ActionType action, AppState state) {
    if (action is UndoableAction) {
      var context = ContextCapture.current();
      Scaffold.of(context).showSnackBar(SnackBar(
        content: Text(CustomLocalizations.of(context).message(action.message)),
        action: SnackBarAction(
          key: undoActionKey,
          label: CustomLocalizations.of(context).undoLabel,
          onPressed: () => store.dispatch(action.undo())
        )
      ));
    }
    return state;
  }
}
