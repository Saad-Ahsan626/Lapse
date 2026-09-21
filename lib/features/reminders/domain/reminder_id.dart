import 'dart:convert';

import 'package:lapse/core/domain/calendar_date.dart';

const int _fnvOffsetBasis = 0x811c9dc5;
const int _fnvPrime = 0x01000193;
const int _mask32 = 0xFFFFFFFF;
const int _mask31 = 0x7FFFFFFF;

int reminderId(String subscriptionId, CalendarDate day) {
  var hash = _fnvOffsetBasis;
  for (final byte in utf8.encode('$subscriptionId|${day.toIso()}')) {
    hash = ((hash ^ byte) * _fnvPrime) & _mask32;
  }
  final id = hash & _mask31;
  return id == 0 ? 1 : id;
}
