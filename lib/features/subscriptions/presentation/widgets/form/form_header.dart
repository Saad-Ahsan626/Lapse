import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lapse/core/theme/theme.dart';
import 'package:lapse/core/widgets/widgets.dart';
import 'package:lapse/features/catalog/presentation/providers/catalog_providers.dart';
import 'package:lapse/features/subscriptions/domain/validation/subscription_field.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_args.dart';
import 'package:lapse/features/subscriptions/presentation/form/subscription_form_controller.dart';

class FormHeader extends ConsumerWidget {
  const FormHeader({
    required this.args,
    required this.nameController,
    required this.onBack,
    this.nameFocusNode,
    super.key,
  });

  final SubscriptionFormArgs args;
  final TextEditingController nameController;
  final VoidCallback onBack;
  final FocusNode? nameFocusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = subscriptionFormProvider(args);
    final (:name, :key, :category, :error) = ref.watch(
      provider.select(
        (s) => (
          name: s.name,
          key: s.catalogKey,
          category: s.category,
          error: s.errors[SubscriptionField.name],
        ),
      ),
    );
    final lapse = context.lapse;
    final c = lapse.colors;
    final service = key == null
        ? null
        : ref.watch(catalogServiceByKeyProvider(key));
    final hasLogo =
        key != null &&
        (ref.watch(logoAvailabilityProvider).value?.hasLogo(key) ?? false);
    final nameStyle = lapse.text.title.copyWith(
      fontSize: 22,
      fontWeight: FontWeight.w700,
    );
    final shownName = name.trim().isEmpty ? '?' : name;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.xs,
        Space.sm,
        Space.xl,
        Space.md,
      ),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            excludeSemantics: true,
            onTap: onBack,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onBack,
              child: SizedBox.square(
                dimension: Sizes.minTap,
                child: Icon(Icons.chevron_left_rounded, size: 30, color: c.ink),
              ),
            ),
          ),
          const SizedBox(width: Space.xs),
          ServiceTile(
            name: shownName,
            initials: service?.initials,
            brandColor: service == null ? null : Color(service.brandColor),
            logoAsset: hasLogo ? service?.logoAsset : null,
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Name',
                  child: TextField(
                    controller: nameController,
                    focusNode: nameFocusNode,
                    onChanged: ref.read(provider.notifier).setName,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: nameStyle,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      border: InputBorder.none,
                      hintText: 'Subscription name',
                      hintStyle: nameStyle.copyWith(color: c.inkSubtle),
                    ),
                  ),
                ),
                Text(
                  category ?? 'Custom subscription',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: lapse.text.meta.copyWith(fontSize: 14),
                ),
                if (error != null) ...[
                  const SizedBox(height: Space.xs),
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 15,
                        color: c.urgentText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          error,
                          style: lapse.text.meta.copyWith(color: c.urgentText),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
