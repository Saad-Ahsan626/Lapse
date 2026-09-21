import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/theme/contrast.dart';
import 'package:lapse/core/theme/tokens/lapse_colors.dart';

void main() {
  test('black on white is 21:1 and a colour on itself is 1:1', () {
    expect(
      contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      contrastRatio(const Color(0xFF4F46E5), const Color(0xFF4F46E5)),
      closeTo(1, 0.001),
    );
  });

  for (final (name, c) in [
    ('light', LapseColors.light),
    ('dark', LapseColors.dark),
  ]) {
    test('$name text tokens reach AA on background and surface', () {
      final text = {
        'ink': c.ink,
        'inkMuted': c.inkMuted,
        'inkSubtle': c.inkSubtle,
        'savingsText': c.savingsText,
        'trialText': c.trialText,
        'urgentText': c.urgentText,
        'warningText': c.warningText,
        'dangerText': c.dangerText,
      };
      for (final entry in text.entries) {
        for (final bg in [c.background, c.surface]) {
          expect(
            contrastRatio(entry.value, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$name ${entry.key}',
          );
        }
      }
    });

    test('$name white on trialStrong reaches AA', () {
      expect(
        contrastRatio(c.onTrial, c.trialStrong),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('$name savingsStrong reaches AA-large on background and surface', () {
      for (final bg in [c.background, c.surface]) {
        expect(contrastRatio(c.savingsStrong, bg), greaterThanOrEqualTo(3));
      }
    });
  }
}
