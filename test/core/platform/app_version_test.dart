import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/core/platform/app_version.dart';

void main() {
  test('label joins name and build', () {
    expect(const AppVersion(name: '0.1.0', build: '1').label, '0.1.0 (1)');
  });

  test('equal when name and build match', () {
    expect(
      const AppVersion(name: '1.2.3', build: '45'),
      const AppVersion(name: '1.2.3', build: '45'),
    );
    expect(
      const AppVersion(name: '1.2.3', build: '45'),
      isNot(const AppVersion(name: '1.2.3', build: '46')),
    );
  });
}
