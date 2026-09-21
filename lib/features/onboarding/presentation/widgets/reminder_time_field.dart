import 'dart:async';

import 'package:flutter/material.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';

enum _Meridiem { am, pm }

TextScaler _digitScaler(BuildContext context) =>
    MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5);

class ReminderTimeField extends StatelessWidget {
  const ReminderTimeField({
    required this.minutes,
    required this.onChanged,
    super.key,
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  static const int _day = 24 * 60;
  static const int _half = 12 * 60;

  static String spokenLabel(int minutes) {
    final value = minutes % _day;
    final hour = value ~/ 60;
    final minute = (value % 60).toString().padLeft(2, '0');
    return '${_hour12(hour)}:$minute ${hour < 12 ? 'AM' : 'PM'}';
  }

  static int _hour12(int hour) => hour % 12 == 0 ? 12 : hour % 12;

  int get _value => minutes % _day;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _value ~/ 60, minute: _value % 60),
      helpText: 'Reminder time',
    );
    if (picked != null) onChanged(picked.hour * 60 + picked.minute);
  }

  void _setMeridiem(_Meridiem meridiem) {
    final isPm = _value >= _half;
    if ((meridiem == _Meridiem.pm) == isPm) return;
    onChanged((_value + _half) % _day);
  }

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final hour = _hour12(_value ~/ 60).toString().padLeft(2, '0');
    final minute = (_value % 60).toString().padLeft(2, '0');
    final meridiem = _value >= _half ? _Meridiem.pm : _Meridiem.am;
    void pick() => unawaited(_pick(context));

    return Semantics(
      container: true,
      label: 'Reminder time, ${spokenLabel(_value)}',
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Space.lg,
        runSpacing: Space.md,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimeBox(
                  key: const ValueKey('reminder-time-hour'),
                  text: hour,
                  semanticLabel: 'Hour, $hour. Change time',
                  onTap: pick,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.sm),
                  child: ExcludeSemantics(
                    child: Text(
                      ':',
                      textScaler: _digitScaler(context),
                      style: lapse.text.title.copyWith(
                        fontWeight: FontWeight.w800,
                        color: lapse.colors.ink,
                      ),
                    ),
                  ),
                ),
                _TimeBox(
                  key: const ValueKey('reminder-time-minute'),
                  text: minute,
                  semanticLabel: 'Minutes, $minute. Change time',
                  onTap: pick,
                ),
              ],
            ),
          ),
          IntrinsicWidth(
            child: SegmentedTabs<_Meridiem>(
              tabs: const [
                SegmentedTab(value: _Meridiem.am, label: 'AM'),
                SegmentedTab(value: _Meridiem.pm, label: 'PM'),
              ],
              selected: meridiem,
              onChanged: _setMeridiem,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.text,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final String text;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lapse = context.lapse;
    final c = lapse.colors;
    final radius = BorderRadius.circular(Radii.md);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: PressScale(
        child: Material(
          color: c.primaryTint,
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.sm,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    text,
                    textScaler: _digitScaler(context),
                    style: lapse.text.title.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: c.primary,
                      fontFeatures: LapseTypography.tabular,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
