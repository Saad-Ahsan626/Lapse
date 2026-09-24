import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/router/routes.dart';

final initialLocationProvider = Provider<String>((ref) => Routes.splash);
