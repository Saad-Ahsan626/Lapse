import 'package:flutter/widgets.dart';

abstract final class Motion {
  static const press = Duration(milliseconds: 120);
  static const release = Duration(milliseconds: 180);

  static const fade = Duration(milliseconds: 200);
  static const expand = Duration(milliseconds: 280);
  static const hero = Duration(milliseconds: 320);
  static const sheet = Duration(milliseconds: 360);
  static const listItem = Duration(milliseconds: 450);
  static const stagger = Duration(milliseconds: 40);
  static const countUp = Duration(milliseconds: 600);
  static const ring = Duration(milliseconds: 800);
  static const urgentPulse = Duration(seconds: 3);

  static const emphasized = Cubic(0.22, 1, 0.36, 1);

  static const pressScale = 0.97;
}

bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;
