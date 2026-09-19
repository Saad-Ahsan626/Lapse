import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lapse/app/providers/theme_mode_provider.dart';
import 'package:lapse/app/router/app_router.dart';
import 'package:lapse/core/theme/app_theme.dart';

class LapseApp extends ConsumerWidget {
  const LapseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lapse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: AppTheme.overlayStyle(Theme.of(context).brightness),
        child: child!,
      ),
    );
  }
}
