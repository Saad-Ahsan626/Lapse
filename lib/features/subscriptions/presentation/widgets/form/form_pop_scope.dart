import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class FormPopScope extends ConsumerWidget {
  const FormPopScope({
    required this.args,
    required this.leaving,
    required this.onBlockedPop,
    required this.child,
    super.key,
  });

  final SubscriptionFormArgs args;
  final bool leaving;
  final VoidCallback onBlockedPop;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final notifier = ref.read(provider.notifier);
    final dirty = ref.watch(
      provider.select(
        (s) => !s.isLoading && s.isDirtyComparedTo(notifier.initial),
      ),
    );
    return PopScope(
      canPop: !dirty || leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) onBlockedPop();
      },
      child: child,
    );
  }
}
