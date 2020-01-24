import 'dart:async';
import 'dart:io';

import 'package:charts_flutter/flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_redurx/flutter_redurx.dart';
import 'package:package_info/package_info.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quiver/strings.dart';
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';

import 'localizations.dart';
import 'models.dart';
import 'states.dart';

class DurationsApp extends StatelessWidget {

  final Widget _home;

  DurationsApp({ Widget home = const BucketListPage() }) : _home = home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Durations",
      home: _home,
      theme: ThemeData(
        brightness: Brightness.light
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark
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
      debugShowCheckedModeBanner: false,
    );
  }
}

class BucketListPage extends StatelessWidget {

  static final GlobalKey menuKey = GlobalKey();

  const BucketListPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(CustomLocalizations.of(context).message(MessageKey.title)),
        actions: <Widget>[
          PopupMenuButton<void Function(BuildContext)>(
            key: menuKey,
            onSelected: (value) => value(context),
            itemBuilder: (context) => [
              PopupMenuItem<void Function(BuildContext)>(
                value: showExport,
                child: Text(CustomLocalizations.of(context).message(MessageKey.export))
              ),
              PopupMenuItem<void Function(BuildContext)>(
                value: showAbout,
                child: Text(CustomLocalizations.of(context).message(MessageKey.about))
              ),
            ]
          )
        ],
      ),
      body: ContextCapture(
        child: RefreshIndicator(
          onRefresh: () async => (context as Element).markNeedsBuild(),
          child: Connect<AppState, List<Bucket>>(
            convert: (state) => state.findBuckets(),
            where: (oldBuckets, newBuckets) => newBuckets != oldBuckets,
            builder: (buckets) => ListView.separated(
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
        tooltip: CustomLocalizations.of(context).message(MessageKey.add),
        child: Icon(Icons.add),
      ),
    );
  }

  void showExport(BuildContext context) async {
    var info = Provider.of<AppState>(context).store.state.export(DateTime.now());
    var temp = await getTemporaryDirectory();
    var file = File("${temp.path}/${info.name}");
    file.writeAsBytesSync(info.bytes, flush: true);
    var box = menuKey.currentContext.findRenderObject() as RenderBox;
    var sharePositionOrigin = box.localToGlobal(Offset.zero) & box.size;
    Share.shareFile(file, mimeType: info.mimeType, sharePositionOrigin: sharePositionOrigin);
  }

  void showAbout(BuildContext context) async {
    var info = await PackageInfo.fromPlatform();
    var theme = Theme.of(context);
    var aboutTextStyle = theme.textTheme.body2;
    var linkStyle = theme.textTheme.body2.copyWith(color: theme.accentColor);
    showAboutDialog(
      context: context,
      applicationIcon: Image.asset("assets/launcher/icon.png", width: 72.0),
      applicationName: info.appName,
      applicationVersion: info.version,
      applicationLegalese: "© Zenobase LLC",
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 24.0),
          child: Linkify(
            text: CustomLocalizations.of(context).message(MessageKey.aboutText),
            style: aboutTextStyle,
            linkStyle: linkStyle,
            onOpen: (link) => launch(link.url)
          ),
        )
      ]
    );
    return;
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
      decoration: InputDecoration(hintText: CustomLocalizations.of(context).message(MessageKey.label)),
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
            var bucket = Bucket.generate(_controller.text);
            Provider.dispatch<AppState>(context, StoreBucket(bucket));
            if (_controller.text == "Demo") {
              for (var event in Event.random()) {
                Provider.dispatch<AppState>(context, StoreEvent(bucket.id, event));
              }
            }
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
              tooltip: CustomLocalizations.of(context).message(MessageKey.remove),
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
            builder: (bucket) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (bucket.size() > 2)
                  SizedBox(
                    height: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: HistogramChart(bucket.id, bucket.histogram()),
                    )
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: bucket.size(),
                    itemBuilder: (context, i) {
                      var event = bucket.events[bucket.size() - 1 - i];
                      var previousEvent = i + 1 < bucket.size() ? bucket.events[bucket.size() - 2 - i] : null;
                      return EventTile(bucket, event, previousEvent);
                    },
                    separatorBuilder: (context, i) => Divider(),
                    shrinkWrap: true,
                  ),
                ),
              ],
            ),
          )
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            var time = await _showDateTimePicker(context, DateTime.now());
            if (time != null) {
              Provider.dispatch<AppState>(context, StoreEvent(widget._bucket.id, Event.generate(OffsetDateTime(time))));
            }
          },
          tooltip: CustomLocalizations.of(context).message(MessageKey.add),
          child: Icon(Icons.add),
        )
    );
  }
}

class HistogramChart extends StatelessWidget {

  final List<Series<Bin, String>> _seriesList;

  HistogramChart(String id, Histogram histogram) : _seriesList = [
    Series<Bin, String>(
      id: id,
      domainFn: (bin, _) => bin.label,
      measureFn: (bin, _) => bin.count,
      data: histogram.bins
    )
  ];

  @override
  Widget build(BuildContext context) {
    var color = _getTextColor(context);
    return BarChart(_seriesList,
      primaryMeasureAxis: NumericAxisSpec(
        renderSpec: GridlineRendererSpec(labelStyle: TextStyleSpec(color: color))
      ),
      domainAxis: OrdinalAxisSpec(
        showAxisLine: false,
        renderSpec: SmallTickRendererSpec(labelStyle: TextStyleSpec(color: color), tickLengthPx: 0)
      )
    );
  }

  static Color _getTextColor(BuildContext context) {
    var color = Theme.of(context).textTheme.headline.color;
    return Color(r: color.red, g: color.green, b: color.blue, a: color.alpha);
  }
}

class EventTile extends StatelessWidget {

  final Bucket _bucket;
  final Event _event;
  final Event _previousEvent;

  EventTile(this._bucket, this._event, this._previousEvent);

  @override
  Widget build(BuildContext context) => Dismissible(
    key: Key(_event.id),
    child: ListTile(
      title: Text(_getTitle(context)),
      subtitle: Text(_getSubtitle(context)),
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

  String _getTitle(BuildContext context) {
    var date = CustomLocalizations.of(context).formatShortDate(_event.timestamp.local);
    var time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(_event.timestamp.local));
    return "$date @ $time";
  }

  String _getSubtitle(BuildContext context) {
    if (_previousEvent == null) {
      return "";
    }
    var duration = _event.timestamp.utc.difference(_previousEvent.timestamp.utc);
    return CustomLocalizations.of(context).formatDuration(duration, relative: true);
  }
}

Future<DateTime> _showDateTimePicker(BuildContext context, DateTime initial) async {
  var now = DateTime.now();
  var endOfDay = DateTime(now.year, now.month, now.day)
    .add(const Duration(days: 1))
    .subtract(const Duration(microseconds: 1));
  var day = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: OffsetDateTime.earliest.local,
    lastDate: endOfDay
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
          label: CustomLocalizations.of(context).message(MessageKey.undo),
          onPressed: () => store.dispatch(action.undo())
        )
      ));
    }
    return state;
  }
}
