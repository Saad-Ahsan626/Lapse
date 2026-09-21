import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

bool _timeZonesLoaded = false;

Future<String> configureLocalTimezone() async {
  try {
    if (!_timeZonesLoaded) {
      tzdata.initializeTimeZones();
      _timeZonesLoaded = true;
    }
    final info = await FlutterTimezone.getLocalTimezone();
    final location = tz.getLocation(info.identifier);
    tz.setLocalLocation(location);
    return location.name;
  } on Object {
    tz.setLocalLocation(tz.UTC);
    return 'UTC';
  }
}
