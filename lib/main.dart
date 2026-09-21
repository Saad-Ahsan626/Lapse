import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/app/app.dart';
import 'package:lapse/app/bootstrap.dart';
import 'package:lapse/app/licenses.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerLicenses();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final container = await bootstrap();
  runApp(
    UncontrolledProviderScope(container: container, child: const LapseApp()),
  );
}
