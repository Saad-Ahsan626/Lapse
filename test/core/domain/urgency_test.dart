import 'package:flutter_test/flutter_test.dart';

import 'package:lapse/core/domain/urgency.dart';

void main() {
  group('Urgency.fromDaysLeft', () {
    test('≤1 day is urgent, ≤3 days is warning, otherwise normal', () {
      expect(Urgency.fromDaysLeft(-2), Urgency.urgent);
      expect(Urgency.fromDaysLeft(0), Urgency.urgent);
      expect(Urgency.fromDaysLeft(1), Urgency.urgent);
      expect(Urgency.fromDaysLeft(2), Urgency.warning);
      expect(Urgency.fromDaysLeft(3), Urgency.warning);
      expect(Urgency.fromDaysLeft(4), Urgency.normal);
      expect(Urgency.fromDaysLeft(30), Urgency.normal);
    });
  });
}
