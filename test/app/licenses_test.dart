import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/app/licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registers the Plus Jakarta Sans licence', () async {
    registerLicenses();
    final entries = await LicenseRegistry.licenses.toList();
    final font = entries.where(
      (entry) => entry.packages.contains('Plus Jakarta Sans'),
    );
    expect(font, isNotEmpty);
    final text = font.first.paragraphs.map((p) => p.text).join(' ');
    expect(text, contains('SIL OPEN FONT LICENSE'));
  });
}
