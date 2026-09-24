import 'package:flutter_riverpod/flutter_riverpod.dart';

final appReadyProvider = NotifierProvider<AppReadyController, bool>(
  AppReadyController.new,
);

class AppReadyController extends Notifier<bool> {
  @override
  bool build() => false;

  void markReady() {
    if (!ref.mounted || state) return;
    state = true;
  }
}
