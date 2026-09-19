import 'package:flutter_test/flutter_test.dart';
import 'package:lapse/features/catalog/data/logo_availability.dart';

void main() {
  test('answers from the bundled asset paths', () {
    final logos = LogoAvailability({
      'assets/logos/netflix.svg',
      'assets/logos/spotify.png',
      'assets/catalog/services.json',
    });

    expect(logos.hasLogo('netflix'), isTrue);
    expect(logos.hasLogo('spotify'), isFalse);
    expect(logos.hasLogo('hulu'), isFalse);
  });
}
