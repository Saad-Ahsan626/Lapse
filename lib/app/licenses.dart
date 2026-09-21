import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Plus Jakarta Sans'], text);
  });
}
