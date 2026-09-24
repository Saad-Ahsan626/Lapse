import 'package:lapse/core/domain/calendar_date.dart';
import 'package:lapse/features/subscriptions/domain/entities/charge.dart';
import 'package:lapse/features/subscriptions/domain/entities/subscription.dart';

typedef RollOverWrite = (
  Subscription updated,
  List<Charge> charges,
  CalendarDate expectedNext,
);
